import { useEffect, useState, useRef, useCallback } from 'react';
import { getMatchingWorkers, getMatchingJobs, runMatching, simulatePresence } from '../services/api';
import { Play, Users, MapPin, Zap, RefreshCw } from 'lucide-react';

const COLOMBO = { lat: 6.9271, lng: 79.8612 };

const BADGE_COLORS: Record<string, string> = {
  platinum: '#8B5CF6', PLATINUM: '#8B5CF6',
  gold: '#F59E0B', GOLD: '#F59E0B',
  silver: '#9CA3AF', SILVER: '#9CA3AF',
  bronze: '#D97706', BRONZE: '#D97706',
  trainee: '#6B7280', TRAINEE: '#6B7280',
};

const PRESENCE_COLORS: Record<string, string> = {
  online: '#22C55E',
  away: '#F59E0B',
  offline: '#EF4444',
};

// Inject Leaflet CSS + JS once
let leafletReady: Promise<void> | null = null;
function ensureLeaflet(): Promise<void> {
  if (leafletReady) return leafletReady;
  leafletReady = new Promise((resolve) => {
    if ((window as any).L) { resolve(); return; }
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
    document.head.appendChild(link);
    const script = document.createElement('script');
    script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
    script.onload = () => resolve();
    document.head.appendChild(script);
  });
  return leafletReady;
}

export default function MatchingDemoPage() {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<any>(null);
  const markersRef = useRef<any[]>([]);

  const [workers, setWorkers] = useState<any[]>([]);
  const [jobs, setJobs] = useState<any[]>([]);
  const [selectedJob, setSelectedJob] = useState<string>('');
  const [matches, setMatches] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [running, setRunning] = useState(false);
  const [simulating, setSimulating] = useState(false);
  const [message, setMessage] = useState('');
  const [matchedJob, setMatchedJob] = useState<any>(null);
  const [mapReady, setMapReady] = useState(false);

  // Initialize map after component mounts
  useEffect(() => {
    let cancelled = false;
    ensureLeaflet().then(() => {
      if (cancelled || !mapRef.current || mapInstanceRef.current) return;
      const L = (window as any).L;
      const map = L.map(mapRef.current, { zoomControl: true }).setView([COLOMBO.lat, COLOMBO.lng], 13);
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap',
        maxZoom: 18,
      }).addTo(map);
      mapInstanceRef.current = map;
      // Fix tile rendering issues
      setTimeout(() => map.invalidateSize(), 200);
      setMapReady(true);
    });
    return () => {
      cancelled = true;
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  // Fetch data on mount
  useEffect(() => { fetchData(); }, []);

  // Update markers when data changes
  useEffect(() => {
    if (mapReady) updateMapMarkers();
  }, [workers, matches, matchedJob, mapReady]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [wRes, jRes] = await Promise.all([getMatchingWorkers(), getMatchingJobs()]);
      setWorkers(wRes.workers || []);
      setJobs(jRes.jobs || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleSimulate = async () => {
    setSimulating(true);
    setMessage('');
    try {
      const res = await simulatePresence();
      setMessage(`Simulated online presence for ${res.count} workers`);
      await fetchData();
    } catch (e: any) {
      setMessage(`Error: ${e.message || 'Failed to simulate'}`);
    } finally {
      setSimulating(false);
    }
  };

  const handleRunMatching = async () => {
    if (!selectedJob) { setMessage('Select a job first'); return; }
    setRunning(true);
    setMessage('');
    setMatches([]);
    setMatchedJob(null);
    try {
      const res = await runMatching(selectedJob);
      setMatches(res.matches || []);
      setMatchedJob(res.job);
      setMessage(`Found ${res.matches?.length || 0} matches from ${res.simulatedWorkers} online workers`);
    } catch (e: any) {
      setMessage(`Error: ${e.message || 'Matching failed'}`);
    } finally {
      setRunning(false);
    }
  };

  const updateMapMarkers = useCallback(() => {
    const L = (window as any).L;
    const map = mapInstanceRef.current;
    if (!L || !map) return;

    // Clear existing
    markersRef.current.forEach((m) => map.removeLayer(m));
    markersRef.current = [];

    const matchedWorkerIds = new Set(matches.map((m: any) => m.workerId));
    const allLatLngs: [number, number][] = [];

    // Worker markers
    workers.forEach((w) => {
      const lat = w.liveLocation?.lat ?? w.latitude;
      const lng = w.liveLocation?.lng ?? w.longitude;
      if (lat == null || lng == null) return;

      const isMatched = matchedWorkerIds.has(w.id);
      const match = matches.find((m: any) => m.workerId === w.id);
      const badgeColor = BADGE_COLORS[w.badgeLevel] || '#6B7280';
      const presenceColor = PRESENCE_COLORS[w.presence] || '#EF4444';
      const size = isMatched ? 18 : 12;
      const rank = match ? matches.indexOf(match) + 1 : null;

      const icon = L.divIcon({
        className: 'custom-marker',
        html: `<div style="
          position:relative;width:${size}px;height:${size}px;
          background:${badgeColor};
          border:3px solid ${isMatched ? '#fff' : presenceColor};
          border-radius:50%;
          box-shadow:0 0 ${isMatched ? '10px 2px' : '4px'} ${isMatched ? badgeColor : 'rgba(0,0,0,0.3)'};
          opacity:${isMatched ? 1 : 0.5};
        "></div>${rank ? `<div style="
          position:absolute;top:-24px;left:50%;transform:translateX(-50%);
          background:#111;color:#fff;font-size:10px;font-weight:700;
          padding:1px 6px;border-radius:10px;white-space:nowrap;
          box-shadow:0 1px 3px rgba(0,0,0,0.3);
        ">#${rank}</div>` : ''}`,
        iconSize: [size, size],
        iconAnchor: [size / 2, size / 2],
      });

      const categories = w.categories?.map((c: any) => c.category?.name).join(', ') || 'N/A';
      const popup = `
        <div style="font-family:system-ui,sans-serif;min-width:170px;line-height:1.5">
          <b style="font-size:13px">${w.user?.name || 'Unknown'}</b><br/>
          <span style="font-size:11px;color:#888">${categories}</span><br/>
          <span style="font-size:11px">
            Badge: <b style="color:${badgeColor}">${w.badgeLevel}</b><br/>
            Rating: <b>${w.rating?.toFixed(1) || '0'}/5</b> · Jobs: <b>${w.totalJobs || 0}</b><br/>
            Completion: <b>${((w.completionRate || 0) * 100).toFixed(0)}%</b><br/>
            Status: <span style="color:${presenceColor};font-weight:600">${w.presence}</span>
          </span>
          ${match ? `<hr style="margin:6px 0;border:none;border-top:1px solid #eee"/>
            <span style="font-size:11px;color:#16a34a">
              <b>Match #${rank}</b><br/>
              Score: <b>${match.matchScore?.toFixed(3)}</b><br/>
              Distance: <b>${match.distanceKm?.toFixed(2)} km</b>
            </span>` : ''}
        </div>`;

      const marker = L.marker([lat, lng], { icon }).addTo(map).bindPopup(popup);
      markersRef.current.push(marker);
      allLatLngs.push([lat, lng]);
    });

    // Job marker
    if (matchedJob?.latitude && matchedJob?.longitude) {
      const jobIcon = L.divIcon({
        className: 'custom-marker',
        html: `<div style="
          width:28px;height:28px;
          background:#EF4444;
          border:3px solid #fff;
          border-radius:6px;
          box-shadow:0 0 14px rgba(239,68,68,0.6);
          display:flex;align-items:center;justify-content:center;
          color:#fff;font-weight:900;font-size:16px;
        ">★</div>`,
        iconSize: [28, 28],
        iconAnchor: [14, 14],
      });

      const marker = L.marker([matchedJob.latitude, matchedJob.longitude], { icon: jobIcon })
        .addTo(map)
        .bindPopup(`<div style="font-family:system-ui,sans-serif">
          <b style="font-size:13px">${matchedJob.title}</b><br/>
          <span style="font-size:11px;color:#888">${matchedJob.category?.name || ''}</span><br/>
          <span style="font-size:11px">${matchedJob.address || 'No address'}</span>
        </div>`)
        .openPopup();
      markersRef.current.push(marker);
      allLatLngs.push([matchedJob.latitude, matchedJob.longitude]);

      // 25km radius circle
      const circle = L.circle([matchedJob.latitude, matchedJob.longitude], {
        radius: 25000,
        color: '#EF4444',
        fillColor: '#EF4444',
        fillOpacity: 0.04,
        weight: 1.5,
        dashArray: '6,4',
      }).addTo(map);
      markersRef.current.push(circle);
    }

    // Fit bounds if we have markers
    if (allLatLngs.length > 1) {
      map.fitBounds(allLatLngs, { padding: [40, 40] });
    } else if (allLatLngs.length === 1) {
      map.setView(allLatLngs[0], 14);
    }
  }, [workers, matches, matchedJob]);

  return (
    <div className="space-y-4">
      {/* Controls */}
      <div className="bg-white rounded-xl border border-warm-300 p-5">
        <h2 className="text-lg font-semibold text-warm-800 mb-4 flex items-center gap-2">
          <Zap size={20} className="text-primary-500" />
          Worker Matching Algorithm Demo
        </h2>

        <div className="flex flex-wrap gap-3 items-end">
          <button
            onClick={handleSimulate}
            disabled={simulating}
            className="flex items-center gap-2 px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600 disabled:opacity-50 text-sm font-medium transition-colors"
          >
            <Users size={16} />
            {simulating ? 'Simulating...' : '1. Simulate Presence'}
          </button>

          <div className="flex-1 min-w-[200px]">
            <label className="text-xs text-warm-500 block mb-1">2. Select a job</label>
            <select
              value={selectedJob}
              onChange={(e) => setSelectedJob(e.target.value)}
              className="w-full px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400"
            >
              <option value="">-- Select Job --</option>
              {jobs.map((j) => (
                <option key={j.id} value={j.id}>
                  {j.title} ({j.category?.name})
                </option>
              ))}
            </select>
          </div>

          <button
            onClick={handleRunMatching}
            disabled={running || !selectedJob}
            className="flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 text-sm font-medium transition-colors"
          >
            <Play size={16} />
            {running ? 'Matching...' : '3. Run Matching'}
          </button>

          <button
            onClick={() => { fetchData(); setMatches([]); setMatchedJob(null); }}
            className="p-2 text-warm-400 hover:text-warm-700 hover:bg-warm-100 rounded-lg transition-colors"
            title="Reset"
          >
            <RefreshCw size={18} />
          </button>
        </div>

        {message && (
          <div className={`mt-3 p-3 rounded-lg text-sm ${message.startsWith('Error') ? 'bg-red-50 text-red-700' : 'bg-green-50 text-green-700'}`}>
            {message}
          </div>
        )}
      </div>

      {/* Map + Results */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Map container - always rendered with fixed height */}
        <div className="lg:col-span-2 bg-white rounded-xl border border-warm-300 overflow-hidden" style={{ minHeight: 500 }}>
          <div ref={mapRef} style={{ height: 500, width: '100%' }} />
        </div>

        {/* Results panel */}
        <div className="bg-white rounded-xl border border-warm-300 p-4 overflow-y-auto" style={{ maxHeight: 500 }}>
          <h3 className="font-semibold text-warm-800 mb-3 flex items-center gap-2">
            <MapPin size={16} />
            {matches.length > 0 ? `Top ${matches.length} Matches` : 'Match Results'}
          </h3>

          {matches.length === 0 ? (
            <div className="text-center py-8 text-warm-400 text-sm space-y-1">
              <p className="text-2xl mb-2">🗺️</p>
              <p className="font-medium text-warm-600">No matches yet</p>
              <p>1. Click "Simulate Presence"</p>
              <p>2. Select a job from dropdown</p>
              <p>3. Click "Run Matching"</p>
            </div>
          ) : (
            <div className="space-y-2">
              {matches.map((m: any, i: number) => {
                const badgeColor = BADGE_COLORS[m.worker?.badgeLevel] || '#6B7280';
                return (
                  <div
                    key={m.id}
                    className="p-3 rounded-lg border border-warm-200 hover:bg-warm-50 transition-colors cursor-pointer"
                    onClick={() => {
                      // Pan map to this worker
                      const w = workers.find((w) => w.id === m.workerId);
                      if (w && mapInstanceRef.current) {
                        const lat = w.liveLocation?.lat ?? w.latitude;
                        const lng = w.liveLocation?.lng ?? w.longitude;
                        if (lat && lng) mapInstanceRef.current.setView([lat, lng], 15);
                      }
                    }}
                  >
                    <div className="flex items-center gap-2 mb-1">
                      <span
                        className="w-6 h-6 rounded-full text-white text-xs font-bold flex items-center justify-center"
                        style={{ background: badgeColor }}
                      >
                        {i + 1}
                      </span>
                      <span className="font-medium text-warm-800 text-sm flex-1">
                        {m.worker?.user?.name || 'Unknown'}
                      </span>
                      <span className="text-xs font-bold text-green-600">
                        {(m.matchScore * 100).toFixed(1)}%
                      </span>
                    </div>
                    <div className="ml-8 text-xs text-warm-500 grid grid-cols-2 gap-x-4 gap-y-0.5">
                      <span>Distance</span>
                      <span className="font-medium text-right">{m.distanceKm?.toFixed(2)} km</span>
                      <span>Rating</span>
                      <span className="font-medium text-right">{m.worker?.rating?.toFixed(1) || '0'}/5</span>
                      <span>Badge</span>
                      <span className="font-medium text-right" style={{ color: badgeColor }}>
                        {m.worker?.badgeLevel}
                      </span>
                      <span>Completion</span>
                      <span className="font-medium text-right">{((m.worker?.completionRate || 0) * 100).toFixed(0)}%</span>
                    </div>
                    {/* Score bar */}
                    <div className="ml-8 mt-1.5 h-1.5 bg-warm-100 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all"
                        style={{ width: `${(m.matchScore || 0) * 100}%`, background: badgeColor }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Legend */}
          <div className="mt-4 pt-4 border-t border-warm-200">
            <p className="text-xs font-medium text-warm-600 mb-2">Legend</p>
            <div className="grid grid-cols-2 gap-1 text-xs text-warm-500">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-sm" style={{ background: '#EF4444' }} /> Job
              </div>
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full" style={{ background: '#8B5CF6' }} /> Platinum
              </div>
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full" style={{ background: '#F59E0B' }} /> Gold
              </div>
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full" style={{ background: '#9CA3AF' }} /> Silver
              </div>
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full" style={{ background: '#D97706' }} /> Bronze
              </div>
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full" style={{ background: '#6B7280' }} /> Trainee
              </div>
            </div>
            <div className="grid grid-cols-3 gap-1 text-xs text-warm-500 mt-2">
              <div className="flex items-center gap-1">
                <span className="w-2 h-2 rounded-full" style={{ background: '#22C55E' }} /> Online
              </div>
              <div className="flex items-center gap-1">
                <span className="w-2 h-2 rounded-full" style={{ background: '#F59E0B' }} /> Away
              </div>
              <div className="flex items-center gap-1">
                <span className="w-2 h-2 rounded-full" style={{ background: '#EF4444' }} /> Offline
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Scoring info */}
      <div className="bg-white rounded-xl border border-warm-300 p-5">
        <h3 className="font-semibold text-warm-800 mb-2">2-Phase Matching Algorithm</h3>
        <div className="text-sm text-warm-600 space-y-1">
          <p><b>Phase 1</b> — Haversine distance filter: find all online workers within 25km radius in the job's category</p>
          <p><b>Phase 2</b> — Weighted scoring of nearby workers:</p>
        </div>
        <div className="mt-2 grid grid-cols-2 sm:grid-cols-4 gap-2">
          {[
            { label: 'Distance', weight: '40%', color: '#3B82F6' },
            { label: 'Rating', weight: '25%', color: '#F59E0B' },
            { label: 'Completion', weight: '20%', color: '#22C55E' },
            { label: 'Badge', weight: '15%', color: '#8B5CF6' },
          ].map(({ label, weight, color }) => (
            <div key={label} className="p-2 rounded-lg border border-warm-200 text-center">
              <p className="text-lg font-bold" style={{ color }}>{weight}</p>
              <p className="text-xs text-warm-500">{label}</p>
            </div>
          ))}
        </div>
        <p className="text-xs text-warm-400 mt-2">
          Top 10 workers selected → saved as JobMatch records → returned ranked by score
        </p>
      </div>
    </div>
  );
}
