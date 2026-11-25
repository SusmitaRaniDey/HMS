import 'dotenv/config';
import { Logger } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { Admin } from '../admin_auth/entities/admin.entity';
import { AdminRole } from '../admin_auth/enums/admin-role.enum';
import AppDataSource from '../data-source';

/**
 * One-time CLI bootstrap for the very first super-admin account. The
 * `POST /admin-auth/create` HTTP endpoint requires an existing super-admin
 * to call it (see admin_auth.controller.ts), so a brand-new deployment with
 * zero admins in the database needs this instead — a public,
 * unauthenticated "create admin" HTTP endpoint is not an acceptable
 * bootstrap mechanism.
 *
 * Usage:
 *   SEED_ADMIN_EMAIL=admin@example.com \
 *   SEED_ADMIN_PASSWORD=change-me-immediately \
 *   SEED_ADMIN_NAME="Super Admin" \
 *   SEED_ADMIN_PHONE=+8801700000000 \
 *   npm run seed:super-admin
 */
async function run() {
  const logger = new Logger('SeedSuperAdmin');

  const email = process.env.SEED_ADMIN_EMAIL;
  const password = process.env.SEED_ADMIN_PASSWORD;
  const name = process.env.SEED_ADMIN_NAME || 'Super Admin';
  const phone = process.env.SEED_ADMIN_PHONE || '';

  if (!email || !password) {
    logger.error(
      'SEED_ADMIN_EMAIL and SEED_ADMIN_PASSWORD environment variables are required',
    );
    process.exit(1);
  }
  if (password.length < 8) {
    logger.error('SEED_ADMIN_PASSWORD must be at least 8 characters');
    process.exit(1);
  }

  try {
    await AppDataSource.initialize();
    const adminRepo = AppDataSource.getRepository(Admin);

    const existing = await adminRepo.findOneBy({ email });
    if (existing) {
      logger.warn(`An admin with email ${email} already exists — nothing to do.`);
      process.exit(0);
    }

    const hash = await bcrypt.hash(password, 10);
    const admin = adminRepo.create({
      name,
      email,
      phone,
      password: hash,
      role: AdminRole.SUPER_ADMIN,
    });
    const saved = await adminRepo.save(admin);

    logger.log(`Created super-admin #${saved.id} (${saved.email}).`);
    logger.log('Log in and change this password immediately.');
    process.exit(0);
  } catch (err) {
    logger.error('Seeding super-admin failed', err as any);
    process.exit(1);
  }
}

void run();
