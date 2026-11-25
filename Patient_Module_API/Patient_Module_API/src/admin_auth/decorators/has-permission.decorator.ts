import { SetMetadata } from '@nestjs/common';
import { AdminPermission } from '../enums/admin-permission.enum';

export const PERMISSIONS_KEY = 'permissions';
export const HasPermission = (...permissions: AdminPermission[]) =>
  SetMetadata(PERMISSIONS_KEY, permissions);
