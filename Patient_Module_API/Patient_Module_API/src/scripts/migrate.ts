import 'dotenv/config';
import { Logger } from '@nestjs/common';
import AppDataSource from '../data-source';

async function run() {
  const logger = new Logger('Migrations');
  try {
    await AppDataSource.initialize();
    const migrations = await AppDataSource.runMigrations();
    logger.log(`Ran ${migrations.length} migrations`);
    process.exit(0);
  } catch (err) {
    logger.error('Migration run failed', err as any);
    process.exit(1);
  }
}

void run();
