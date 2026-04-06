import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration.js';
import { FirebaseModule } from './firebase/firebase.module.js';
import { LlmModule } from './llm/llm.module.js';
import { FactCheckModule } from './fact-check/fact-check.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),
    FirebaseModule,
    LlmModule,
    FactCheckModule,
  ],
})
export class AppModule {}
