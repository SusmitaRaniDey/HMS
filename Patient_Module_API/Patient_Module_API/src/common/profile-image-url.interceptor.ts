import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import { Observable, map } from 'rxjs';

@Injectable()
export class ProfileImageUrlInterceptor implements NestInterceptor {
  constructor(private readonly config: ConfigService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<Request>();
    return next
      .handle()
      .pipe(
        map((body: unknown) =>
          this.transform(body, this.publicOrigin(request)),
        ),
      );
  }

  private publicOrigin(request: Request): string {
    const configured = this.config.get<string>('PUBLIC_BASE_URL')?.trim();
    if (configured)
      return configured.replace(/\/+$/, '').replace(/\/api\/v1$/, '');

    const forwardedProto = request.header('x-forwarded-proto')?.split(',')[0];
    const protocol = forwardedProto?.trim() || request.protocol;
    return `${protocol}://${request.get('host')}`;
  }

  private transform(value: unknown, origin: string): unknown {
    if (Array.isArray(value)) {
      return value.map((item) => this.transform(item, origin));
    }
    if (
      !value ||
      typeof value !== 'object' ||
      value instanceof Date ||
      Buffer.isBuffer(value) ||
      value.constructor?.name === 'StreamableFile'
    ) {
      return value;
    }

    const output: Record<string, unknown> = {};
    for (const [key, child] of Object.entries(
      value as Record<string, unknown>,
    )) {
      output[key] =
        (key === 'profilePic' || key === 'profile_pic') &&
        typeof child === 'string'
          ? this.resolve(child, origin)
          : this.transform(child, origin);
    }
    return output;
  }

  private resolve(value: string, origin: string): string {
    const cleaned = value.trim().replace(/\\/g, '/');
    if (!cleaned) return cleaned;
    if (/^https?:\/\//i.test(cleaned)) {
      return cleaned;
    }
    const path = cleaned.startsWith('/') ? cleaned : `/${cleaned}`;
    return `${origin}${path}`;
  }
}
