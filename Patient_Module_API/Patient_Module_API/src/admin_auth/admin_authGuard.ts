/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-call */
import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { PERMISSIONS_KEY } from './decorators/has-permission.decorator';
import { ROLES_KEY } from './decorators/has-role.decorator';
import { AdminPermission } from './enums/admin-permission.enum';
import { AdminRole } from './enums/admin-role.enum';
import { ROLE_PERMISSIONS } from './enums/role-permissions.map';

@Injectable()
export class AdminAuthGuard implements CanActivate {
  constructor(
    private jwtService: JwtService,
    private configService: ConfigService,
    private reflector: Reflector,
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
        secret: (this.configService.get('ADMIN_ACCESS_TOKEN_SEC') ||
          this.configService.get('ACCESS_TOKEN_SEC')) as string,
      });

      request['user'] = payload;

      // Check role requirements
      const requiredRoles = this.reflector.getAllAndOverride<AdminRole[]>(
        ROLES_KEY,
        [context.getHandler(), context.getClass()],
      );

      if (requiredRoles && requiredRoles.length > 0) {
        const adminRole = payload.role as AdminRole;
        if (!requiredRoles.includes(adminRole)) {
          throw new ForbiddenException(
            `This action requires one of the following roles: ${requiredRoles.join(', ')}`,
          );
        }
      }

      // Check permission requirements
      const requiredPermissions = this.reflector.getAllAndOverride<string[]>(
        PERMISSIONS_KEY,
        [context.getHandler(), context.getClass()],
      );

      if (requiredPermissions && requiredPermissions.length > 0) {
        const adminRole = payload.role as AdminRole;
        const rolePermissions = ROLE_PERMISSIONS[adminRole] || [];

        const hasPermission = requiredPermissions.some((permission) =>
          rolePermissions.includes(permission as AdminPermission),
        );

        if (!hasPermission) {
          throw new ForbiddenException(
            `You don't have the required permissions for this action. Required: ${requiredPermissions.join(', ')}`,
          );
        }
      }

      return true;
    } catch (error) {
      if (error instanceof ForbiddenException) {
        throw error;
      }
      return false;
    }
  }
}
