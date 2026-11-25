import 'dotenv/config';
import { Logger } from '@nestjs/common';
import AppDataSource from '../data-source';

async function run() {
  const logger = new Logger('Migrations');
  try {
    await AppDataSource.initialize();
    await AppDataSource.undoLastMigration();
    logger.log('Reverted last migration');
    process.exit(0);
  } catch (err) {
    logger.error('Migration revert failed', err as any);
    process.exit(1);
  }
}

void run();
