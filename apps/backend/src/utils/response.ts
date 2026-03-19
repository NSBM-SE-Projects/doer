import { Response } from 'express';

export const success = (res: Response, data: unknown, status = 200) => {
  return res.status(status).json({ success: true, data });
};

export const error = (res: Response, message: string, status = 400) => {
  return res.status(status).json({ success: false, message });
};
