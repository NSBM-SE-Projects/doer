import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/AppError';
import { ZodError } from 'zod';

export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
) => {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({ error: err.message });
    return;
  }

  if (err instanceof ZodError) {
    const messages = err.issues.map((i) => `${i.path.join('.')}: ${i.message}`);
    res.status(400).json({ error: 'Validation failed', details: messages });
    return;
  }

  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
};
