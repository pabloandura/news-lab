import { Module } from '@nestjs/common';
import { PolarizeController } from './polarize.controller.js';
import { PolarizeService } from './polarize.service.js';

@Module({
  controllers: [PolarizeController],
  providers: [PolarizeService],
})
export class PolarizeModule {}
