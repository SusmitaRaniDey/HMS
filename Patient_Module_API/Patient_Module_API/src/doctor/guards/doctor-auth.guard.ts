import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';

@Injectable()
export class DoctorAuthGuard implements CanActivate {
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

    try {
      const payload = this.jwtService.verify(token as string, {
        secret: (this.configService.get('DOCTOR_ACCESS_TOKEN_SEC') ||
          this.configService.get('ACCESS_TOKEN_SEC')) as string,
      });

      request['doctor'] = payload;
      return true;
    } catch {
      return false;
    }
  }
}
