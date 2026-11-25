import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddEmergencyConsultations1785110400000 implements MigrationInterface {
  name = 'AddEmergencyConsultations1785110400000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE emergency_availability (
        id int NOT NULL AUTO_INCREMENT,
        doctorId int NOT NULL,
        availableFrom datetime NOT NULL,
        availableUntil datetime NOT NULL,
        isEnabled tinyint NOT NULL DEFAULT 1,
        enabledByAdmin tinyint NOT NULL DEFAULT 1,
        emergencyFee decimal(10,2) NULL,
        createdAt datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
        updatedAt datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
        UNIQUE KEY UQ_emergency_availability_doctor (doctorId),
        PRIMARY KEY (id),
        CONSTRAINT FK_emergency_availability_doctor FOREIGN KEY (doctorId)
          REFERENCES doctor(id) ON DELETE CASCADE
      ) ENGINE=InnoDB
    `);
    await queryRunner.query(
      'ALTER TABLE appointment ADD isEmergency tinyint NOT NULL DEFAULT 0, ADD emergencyAvailabilityId int NULL',
    );
    await queryRunner.query(
      'ALTER TABLE appointment ADD CONSTRAINT FK_appointment_emergency_availability FOREIGN KEY (emergencyAvailabilityId) REFERENCES emergency_availability(id) ON DELETE SET NULL',
    );
    await queryRunner.query(
      'CREATE INDEX IDX_appointment_emergency_doctor_status ON appointment (isEmergency, doctorId, status)',
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'DROP INDEX IDX_appointment_emergency_doctor_status ON appointment',
    );
    await queryRunner.query(
      'ALTER TABLE appointment DROP FOREIGN KEY FK_appointment_emergency_availability',
    );
    await queryRunner.query(
      'ALTER TABLE appointment DROP COLUMN emergencyAvailabilityId, DROP COLUMN isEmergency',
    );
    await queryRunner.query('DROP TABLE emergency_availability');
  }
}
