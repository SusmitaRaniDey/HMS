import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { Request } from 'express';

export interface AuthContext {
  role: 'patient' | 'doctor' | 'admin';
  id: number;
  payload: Record<string, unknown>;
}

/**
 * Pairs with AnyAuthGuard. Returns the caller's resolved role and id
 * regardless of which of the three token types they authenticated with.
 */
export const CurrentAuth = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): AuthContext => {
    const request = ctx.switchToHttp().getRequest<Request>();
    const payload = (request as any).user as Record<string, unknown>;
    const role = (request as any).authRole as AuthContext['role'];
    return { role, id: Number(payload?.id), payload };
  },
);
