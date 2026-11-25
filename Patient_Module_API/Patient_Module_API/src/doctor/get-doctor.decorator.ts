import { createParamDecorator, ExecutionContext, BadRequestException } from '@nestjs/common';

export const GetDoctor = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    const doctor = request.doctor;
    if (!doctor || !doctor.id) {
      throw new BadRequestException('Doctor not found in token');
    }
    return doctor;
  },
);