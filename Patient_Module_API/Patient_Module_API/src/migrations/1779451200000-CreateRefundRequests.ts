import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateRefundRequests1779451200000 implements MigrationInterface {
  name = 'CreateRefundRequests1779451200000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE refund_requests (
        id int NOT NULL AUTO_INCREMENT,
        appointment_id int NOT NULL,
        patient_id int NOT NULL,
        reason enum('patient_cancelled', 'doctor_no_show', 'no_consultation') NOT NULL,
        patient_note text NULL,
        refund_status enum('pending', 'processing', 'refunded', 'rejected') NOT NULL DEFAULT 'pending',
        payment_method varchar(255) NULL,
        original_amount decimal(10,2) NULL,
        refunded_amount decimal(10,2) NULL,
        refund_to_account varchar(255) NOT NULL,
        refund_transaction_id varchar(255) NULL,
        rejection_reason text NULL,
        initiated_by enum('patient', 'admin') NOT NULL,
        processed_by int NULL,
        requested_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        processed_at timestamp NULL,
        updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY IDX_refund_requests_appointment_id (appointment_id),
        INDEX IDX_refund_requests_patient_id (patient_id),
        CONSTRAINT FK_refund_requests_appointment_id FOREIGN KEY (appointment_id) REFERENCES appointment(id) ON DELETE CASCADE,
        CONSTRAINT FK_refund_requests_patient_id FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
        PRIMARY KEY (id)
      ) ENGINE=InnoDB
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE refund_requests');
  }
}
