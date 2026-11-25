import { Logger, ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import { join } from 'path';
import { AppModule } from './app.module';
import { ProfileImageUrlInterceptor } from './common/profile-image-url.interceptor';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Prescription PDFs are intentionally NOT served as static files — they
  // contain PHI (diagnosis, medicines, contact details). They're only
  // reachable through GET /prescriptions/:id/download, which requires
  // authentication and an ownership check (see PrescriptionController).
  const logger = new Logger('Bootstrap');

  // Enable CORS with production settings. A wildcard origin combined with
  // credentials:true is unsafe, so CORS_ORIGIN must be set explicitly
  // (comma-separated for multiple origins) in any real deployment; only
  // local development falls back to allowing everything.
  const corsOrigin = process.env.CORS_ORIGIN;
  const nodeEnvForCors = process.env.NODE_ENV || 'development';
  if (!corsOrigin && nodeEnvForCors === 'production') {
    throw new Error(
      'CORS_ORIGIN must be set to an explicit allow-list in production',
    );
  }
  app.enableCors({
    origin: corsOrigin ? corsOrigin.split(',').map((o) => o.trim()) : true,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
    maxAge: 3600,
  });

  // Doctor profile images are public and are displayed by web clients hosted
  // on a different origin (usually a different port during development).
  // Register security/CORS middleware before the static route so those image
  // responses receive the required headers.
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
    }),
  );
  app.useStaticAssets(join(process.cwd(), 'uploads', 'doctors'), {
    prefix: '/uploads/doctors/',
    fallthrough: false,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.useGlobalInterceptors(app.get(ProfileImageUrlInterceptor));

  // API versioning support
  const apiVersion = 'v1';
  app.setGlobalPrefix(`api/${apiVersion}`);

  const port = process.env.PORT ?? 3000;
  const nodeEnv = process.env.NODE_ENV || 'development';

  await app.listen(port, '0.0.0.0');

  logger.log(
    `🚀 Application running on: http://localhost:${port}/api/${apiVersion}`,
  );
  logger.log(`🔧 Environment: ${nodeEnv}`);
  logger.log(`✅ Database synchronized and ready for requests`);
}

void bootstrap().catch((error) => {
  const logger = new Logger('Bootstrap');
  logger.error('Failed to start application', error);
  process.exit(1);
});
