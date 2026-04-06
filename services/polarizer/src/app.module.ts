import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration.js';
import { FirebaseModule } from './firebase/firebase.module.js';
import { LlmModule } from './llm/llm.module.js';
import { PolarizeModule } from './polarize/polarize.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),
    FirebaseModule,
    LlmModule,
    PolarizeModule,
  ],
})
export class AppModule {}
