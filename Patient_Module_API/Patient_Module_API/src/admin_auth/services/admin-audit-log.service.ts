import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AdminAuditLog } from '../entities/admin-audit-log.entity';

@Injectable()
export class AdminAuditLogService {
  constructor(
    @InjectRepository(AdminAuditLog)
    private auditLogRepo: Repository<AdminAuditLog>,
  ) {}

  async logAction(
    adminId: number,
    adminEmail: string,
    action: string,
    resource: string,
    resourceId?: number,
    changes?: any,
    ipAddress?: string,
    userAgent?: string,
    status: string = 'success',
  ) {
    const log = this.auditLogRepo.create({
      adminId,
      adminEmail,
      action,
      resource,
      resourceId,
      changes: changes ? JSON.stringify(changes) : undefined,
      ipAddress,
      userAgent,
      status,
    });

    return this.auditLogRepo.save(log);
  }

  async getLogs(
    page: number = 1,
    limit: number = 20,
    adminId?: number,
    resource?: string,
    action?: string,
  ) {
    const query = this.auditLogRepo.createQueryBuilder('log');

    if (adminId) query.where('log.adminId = :adminId', { adminId });
    if (resource) query.andWhere('log.resource = :resource', { resource });
    if (action) query.andWhere('log.action = :action', { action });

    const [data, total] = await query
      .orderBy('log.timestamp', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { data, total, page, limit };
  }

  async getAdminActivityLog(
    adminId: number,
    page: number = 1,
    limit: number = 20,
  ) {
    return this.getLogs(page, limit, adminId);
  }

  async getResourceChanges(resource: string, resourceId: number) {
    const logs = await this.auditLogRepo.find({
      where: { resource, resourceId },
      order: { timestamp: 'DESC' },
    });

    return logs.map((log) => ({
      ...log,
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      changes: log.changes ? JSON.parse(log.changes) : undefined,
    }));
  }
}
