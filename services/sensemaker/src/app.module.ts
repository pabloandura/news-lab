import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import configuration from './config/configuration.js';
import { FirebaseModule } from './firebase/firebase.module.js';
import { EmbeddingModule } from './embedding/embedding.module.js';
import { IngestModule } from './ingest/ingest.module.js';
import { SimilarModule } from './similar/similar.module.js';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),
    FirebaseModule,
    EmbeddingModule,
    IngestModule,
    SimilarModule,
  ],
})
export class AppModule {}
