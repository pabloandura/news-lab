import { Injectable, OnApplicationBootstrap, Logger } from '@nestjs/common';
import * as admin from 'firebase-admin';

@Injectable()
export class FirebaseService implements OnApplicationBootstrap {
  private readonly logger = new Logger(FirebaseService.name);
  private _db!: admin.firestore.Firestore;

  onApplicationBootstrap(): void {
    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.applicationDefault(),
      });
      this.logger.log('Firebase Admin initialised via Application Default Credentials');
    }
    this._db = admin.firestore();
  }

  get db(): admin.firestore.Firestore {
    return this._db;
  }
}
