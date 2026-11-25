import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from './../src/app.module';

describe('Diagnostics (e2e)', () => {
  let app: INestApplication;
  let server: any;
  let token: string;
  let createdId: number;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
    server = app.getHttpServer();

    // Create admin (idempotent)
    await request(server)
      .post('/admin-auth/create')
      .send({
        name: 'E2E Admin',
        email: 'e2e-admin@example.com',
        phone: '1234567890',
        password: 'password',
      })
      .catch(() => null);

    const res = await request(server)
      .post('/admin-auth/login')
      .send({ email: 'e2e-admin@example.com', password: 'password' });

    token = res.body.token;
  });

  afterAll(async () => {
    await app.close();
  });

  it('creates a diagnostic', async () => {
    const res = await request(server)
      .post('/admin-auth/diagnostics')
      .set('Authorization', `Bearer ${token}`)
      .send({
        test_name: 'E2E Blood Test',
        category: 'Blood',
        department: 'Pathology',
        price: 25.5,
      })
      .expect(201);

    expect(res.body).toHaveProperty('id');
    createdId = res.body.id;
  });

  it('lists diagnostics with pagination', async () => {
    const res = await request(server)
      .get('/diagnostics?page=1&limit=10')
      .expect(200);

    expect(res.body).toHaveProperty('data');
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it('exports diagnostics as CSV', async () => {
    const res = await request(server)
      .get('/admin-auth/diagnostics/export')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(typeof res.text).toBe('string');
    expect(res.text.startsWith('id,test_name,category')).toBe(true);
  });

  it('can toggle diagnostic status', async () => {
    // deactivate
    await request(server)
      .patch(`/admin-auth/diagnostics/${createdId}/status`)
      .set('Authorization', `Bearer ${token}`)
      .send({ active: false })
      .expect(200);

    const res = await request(server).get('/diagnostics').expect(200);
    const ids = res.body.data.map((d) => d.id);
    expect(ids).not.toContain(createdId);
  });
});
