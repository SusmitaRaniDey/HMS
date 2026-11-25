import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';

export interface PatientContext {
  id: number;
  name: string;
  email: string;
  phone: string;
}

export const CurrentPatient = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): PatientContext => {
    const request = ctx.switchToHttp().getRequest<Request>();
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    return (request as any).patient as PatientContext;
  },
);
