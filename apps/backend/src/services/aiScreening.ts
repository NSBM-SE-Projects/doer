import { SCREENING_SYSTEM_PROMPT, SCREENING_USER_PROMPT } from './aiScreeningPrompts';

// Thresholds from env or defaults
const PASS_THRESHOLD = parseFloat(process.env.AI_CONFIDENCE_PASS_THRESHOLD || '0.75');
const FLAG_THRESHOLD = parseFloat(process.env.AI_CONFIDENCE_FLAG_THRESHOLD || '0.40');
const TIMEOUT_MS = parseInt(process.env.AI_SCREENING_TIMEOUT_MS || '30000', 10);
const ENABLED = process.env.AI_SCREENING_ENABLED !== 'false';
const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'llava';
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;

export interface ScreeningResult {
  decision: 'PASS' | 'FLAG' | 'REJECT';
  confidence: number;
  nic: {
    detected: boolean;
    number: string | null;
    name_extracted: string | null;
    format_valid: boolean;
    issues: string[];
  };
  police_report: {
    detected: boolean;
    appears_official: boolean;
    clearance_status: string;
    name_extracted: string | null;
    date: string | null;
    issues: string[];
  };
  qualifications: {
    detected: boolean;
    skill: string | null;
    name_extracted: string | null;
    issues: string[];
  };
  cross_check: {
    names_match: boolean;
    concerns: string[];
  };
  rejection_reason: string | null;
  flag_reason: string | null;
  summary: string;
}

const DEFAULT_FLAG_RESULT: ScreeningResult = {
  decision: 'FLAG',
  confidence: 0.5,
  nic: { detected: false, number: null, name_extracted: null, format_valid: false, issues: ['AI screening unavailable'] },
  police_report: { detected: false, appears_official: false, clearance_status: 'unknown', name_extracted: null, date: null, issues: [] },
  qualifications: { detected: false, skill: null, name_extracted: null, issues: [] },
  cross_check: { names_match: false, concerns: [] },
  rejection_reason: null,
  flag_reason: 'AI screening was unavailable — manual review required',
  summary: 'Documents could not be auto-screened. Sent to admin for manual review.',
};

/**
 * Screen worker documents using a vision LLM.
 * Tries Ollama (local) first, then Claude API, then falls back to FLAG.
 */
export async function screenDocuments(imageUrls: string[]): Promise<ScreeningResult> {
  if (!ENABLED || imageUrls.length === 0) {
    return DEFAULT_FLAG_RESULT;
  }

  // Convert image URLs to base64
  const images = await Promise.all(
    imageUrls.map(async (url) => {
      try {
        const res = await fetch(url);
        const buffer = Buffer.from(await res.arrayBuffer());
        const base64 = buffer.toString('base64');
        const contentType = res.headers.get('content-type') || 'image/jpeg';
        return { base64, contentType };
      } catch {
        return null;
      }
    })
  );

  const validImages = images.filter((img): img is { base64: string; contentType: string } => img !== null);
  if (validImages.length === 0) {
    return { ...DEFAULT_FLAG_RESULT, flag_reason: 'Could not load document images for screening' };
  }

  // Try Ollama first (local, free)
  try {
    const result = await callOllama(validImages);
    if (result) return applyThresholds(result);
  } catch (e) {
    console.log('Ollama not available, trying Claude API...');
  }

  // Try Claude API if key is configured
  if (ANTHROPIC_API_KEY) {
    try {
      const result = await callClaude(validImages);
      if (result) return applyThresholds(result);
    } catch (e) {
      console.error('Claude API failed:', e);
    }
  }

  // Fallback: FLAG for manual review
  console.log('AI screening unavailable — falling back to FLAG');
  return DEFAULT_FLAG_RESULT;
}

/**
 * Call Ollama with LLaVA model (local vision LLM)
 */
async function callOllama(images: { base64: string; contentType: string }[]): Promise<ScreeningResult | null> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

  try {
    const response = await fetch(`${OLLAMA_URL}/api/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: OLLAMA_MODEL,
        prompt: `${SCREENING_SYSTEM_PROMPT}\n\n${SCREENING_USER_PROMPT}`,
        images: images.map((img) => img.base64),
        stream: false,
        options: { temperature: 0.1, num_predict: 2000 },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (!response.ok) throw new Error(`Ollama returned ${response.status}`);

    const data: any = await response.json();
    return parseResponse(data.response);
  } catch (e: any) {
    clearTimeout(timeout);
    if (e.name === 'AbortError') throw new Error('Ollama timeout');
    throw e;
  }
}

/**
 * Call Anthropic Claude API with vision
 */
async function callClaude(images: { base64: string; contentType: string }[]): Promise<ScreeningResult | null> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);

  const content: any[] = images.map((img) => ({
    type: 'image',
    source: {
      type: 'base64',
      media_type: img.contentType,
      data: img.base64,
    },
  }));
  content.push({ type: 'text', text: SCREENING_USER_PROMPT });

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ANTHROPIC_API_KEY!,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1500,
        system: SCREENING_SYSTEM_PROMPT,
        messages: [{ role: 'user', content }],
      }),
      signal: controller.signal,
    });

    clearTimeout(timeout);

    if (!response.ok) {
      const err = await response.text();
      throw new Error(`Claude API ${response.status}: ${err}`);
    }

    const data: any = await response.json();
    const text = data.content?.[0]?.text;
    return parseResponse(text);
  } catch (e: any) {
    clearTimeout(timeout);
    if (e.name === 'AbortError') throw new Error('Claude API timeout');
    throw e;
  }
}

/**
 * Parse LLM response text into ScreeningResult
 */
function parseResponse(text: string): ScreeningResult | null {
  if (!text) return null;

  // Extract JSON from response (LLM might wrap it in markdown code blocks)
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) return null;

  try {
    const parsed = JSON.parse(jsonMatch[0]);

    return {
      decision: parsed.decision || 'FLAG',
      confidence: typeof parsed.confidence === 'number' ? parsed.confidence : 0.5,
      nic: {
        detected: parsed.nic?.detected ?? false,
        number: parsed.nic?.number ?? null,
        name_extracted: parsed.nic?.name_extracted ?? null,
        format_valid: parsed.nic?.format_valid ?? false,
        issues: parsed.nic?.issues ?? [],
      },
      police_report: {
        detected: parsed.police_report?.detected ?? false,
        appears_official: parsed.police_report?.appears_official ?? false,
        clearance_status: parsed.police_report?.clearance_status ?? 'unknown',
        name_extracted: parsed.police_report?.name_extracted ?? null,
        date: parsed.police_report?.date ?? null,
        issues: parsed.police_report?.issues ?? [],
      },
      qualifications: {
        detected: parsed.qualifications?.detected ?? false,
        skill: parsed.qualifications?.skill ?? null,
        name_extracted: parsed.qualifications?.name_extracted ?? null,
        issues: parsed.qualifications?.issues ?? [],
      },
      cross_check: {
        names_match: parsed.cross_check?.names_match ?? false,
        concerns: parsed.cross_check?.concerns ?? [],
      },
      rejection_reason: parsed.rejection_reason ?? null,
      flag_reason: parsed.flag_reason ?? null,
      summary: parsed.summary ?? 'No summary provided',
    };
  } catch {
    return null;
  }
}

/**
 * Apply confidence thresholds and sanity checks
 */
function applyThresholds(result: ScreeningResult): ScreeningResult {
  const { confidence } = result;

  // Sanity check: if NIC wasn't detected but model still says PASS, downgrade to FLAG
  if (result.decision === 'PASS' && !result.nic.detected && !result.police_report.detected && !result.qualifications.detected) {
    result.decision = 'FLAG';
    result.flag_reason = 'No documents were clearly detected in the images';
    result.confidence = Math.min(result.confidence, 0.5);
  }

  // Apply thresholds
  if (confidence >= PASS_THRESHOLD && result.decision !== 'REJECT') {
    result.decision = 'PASS';
  } else if (confidence < FLAG_THRESHOLD) {
    result.decision = 'REJECT';
  } else if (confidence < PASS_THRESHOLD) {
    result.decision = 'FLAG';
  }

  return result;
}
