import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MedicineDataController } from './medicine-data.controller';
import { MedicineDataService } from './medicine-data.service';
import { MedicineData } from './entities/medicine-data.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([MedicineData]),
    ConfigModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get('ACCESS_TOKEN_SEC'),
      }),
    }),
  ],
  controllers: [MedicineDataController],
  providers: [MedicineDataService],
  exports: [MedicineDataService],
})
export class MedicineDataModule {}
