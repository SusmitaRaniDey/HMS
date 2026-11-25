import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface AdminContext {
  id: number;
  email: string;
  role: string;
}

export const CurrentAdmin = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): AdminContext => {
    const request = ctx.switchToHttp().getRequest();
    const user = request['user'] as AdminContext;

    return {
      id: user.id,
      email: user.email,
      role: user.role,
    };
  },
);
