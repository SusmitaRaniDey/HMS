import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddDoctorConsultationFees1783219200000
  implements MigrationInterface
{
  name = 'AddDoctorConsultationFees1783219200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE doctor ADD onlineFee int NULL, ADD offlineFee int NULL',
    );
    await queryRunner.query(
      'UPDATE doctor SET onlineFee = fee, offlineFee = fee WHERE fee IS NOT NULL',
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE doctor DROP COLUMN offlineFee, DROP COLUMN onlineFee',
    );
  }
}
