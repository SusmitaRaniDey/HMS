import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';

/**
 * Accepts a valid patient, doctor, or admin access token.
 * For read-only endpoints that are legitimately shared across apps
 * (e.g. doctor slot/availability lookups called by both the patient app
 * and the admin panel) where the caller's specific role doesn't matter,
 * only that they are one of the three authenticated user types.
 */
@Injectable()
export class AnyAuthGuard implements CanActivate {
  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();
    const authHeader = request.headers['authorization'];

    if (!authHeader) {
      return false;
    }

    const token = Array.isArray(authHeader)
      ? authHeader[0].split(' ')[1]
      : authHeader.split(' ')[1];

    if (!token) return false;

    const secrets: Array<{ role: string; secret: string | undefined }> = [
      {
        role: 'patient',
        secret: this.configService.get('ACCESS_TOKEN_SEC'),
      },
      {
        role: 'doctor',
        secret:
          this.configService.get('DOCTOR_ACCESS_TOKEN_SEC') ||
          this.configService.get('ACCESS_TOKEN_SEC'),
      },
      {
        role: 'admin',
        secret:
          this.configService.get('ADMIN_ACCESS_TOKEN_SEC') ||
          this.configService.get('ACCESS_TOKEN_SEC'),
      },
    ];

    for (const { role, secret } of secrets) {
      if (!secret) continue;
      try {
        const payload = this.jwtService.verify(token, { secret });
        request['user'] = payload;
        request['authRole'] = role;
        return true;
      } catch {
        // try next secret
      }
    }

    return false;
  }
}
