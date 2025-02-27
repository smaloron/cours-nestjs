# Les tests

## Test de bout en bout

### Installation

```shell
npm install --save-dev @nestjs/testing @nestjs/core supertest jest

npm install --save-dev mongodb-memory-server jest-mongodb
```

### Simuler la base de données

```typescript
// test/setup.ts

import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';

let mongod: MongoMemoryServer;

export const connectTestDB = async () => {
  mongod = await MongoMemoryServer.create();
  const uri = mongod.getUri();

  await mongoose.connect(uri);
};

export const closeTestDB = async () => {
  await mongoose.connection.dropDatabase();
  await mongoose.connection.close();
  await mongod.stop();
};

```

### Configurer les tests

```json
{
  "moduleFileExtensions": ["js", "json", "ts"],
  "rootDir": "../",
  "testRegex": ".e2e-spec.ts$",
  "transform": {
    "^.+\\.ts$": "ts-jest"
  },
  "setupFilesAfterEnv": ["<rootDir>/test/setup.ts"]
}
```

1. **moduleFileExtensions**
   Définit les extensions de fichiers que Jest reconnaît et peut importer lors des tests.

```
"js" : Fichiers JavaScript.
"json" : Fichiers JSON.
"ts" : Fichiers TypeScript.
```


2. **rootDir**
   Spécifie le répertoire racine des tests.

`../` signifie que Jest exécutera les tests à partir du dossier parent du fichier de configuration.

3. **testRegex**
   Indique le motif des fichiers de test que Jest doit détecter.

`.e2e-spec.ts$` : Tous les fichiers qui terminent par .e2e-spec.ts seront exécutés comme tests E2E.

4. **transform**
   Définit comment Jest doit transformer les fichiers avant exécution.

`"^.+\\.ts$": "ts-jest"` : Tous les fichiers TypeScript (.ts) seront transformés avec ts-jest, un préprocesseur Jest pour exécuter directement du TypeScript.

5. **setupFilesAfterEnv**
   Spécifie les fichiers qui seront exécutés après l’initialisation de Jest mais avant les tests.

`"<rootDir>/test/setup.ts"` : Permet d’exécuter du code de configuration avant les tests (ex: mocks, configuration de base de données, variables globales).

### La commande de lancement des tests

Modifier `package.json`

```json
"scripts": {
  "test:e2e": "jest --config ./test/jest-e2e.json"
}
```

### Un test

- `@nestjs/testing` : Utilisé pour créer un module de test NestJS.
- `INestApplication` : Interface pour manipuler l'application NestJS.
- `supertest` : Permet d'effectuer des requêtes HTTP pour tester l'API.
- `AppModule` : Charge le module principal de l'application.
- `connectTestDB` et `closeTestDB` : Fonctions définies dans `setup.ts` pour gérer la base de données MongoDB en mémoire.

```typescript
// person-e2e.spec.ts

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { connectTestDB, closeTestDB } from './setup';

describe('Person End-to-End Test', () => {
  let app: INestApplication;
  
  // Stocke l'ID d'une personne pour les tests
  let personId: string; 

  // Initialisation de l'application
  // et de la base de données 
  // avant le lancement des tests
  beforeAll(async () => {
    await connectTestDB(); // Connexion à la base de test

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  // Nettoyage après les tests
  afterAll(async () => {
    await closeTestDB(); // Fermer la base de test
    await app.close();
  });

  // Test de la route POST /person
  it('/person (POST) should create a new person', async () => {
    const personData = { name: 'Alice Doe', age: 30 };
    const response = await request(app.getHttpServer())
      .post('/person')
      .send(personData);
      
    // Assertions
    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('_id');
    
    // Stocker l'ID pour les prochains tests
    personId = response.body._id; 
  });

  it('/person (GET) should return all persons', async () => {
    const response = await request(app.getHttpServer()).get('/person');
    
    expect(response.status).toBe(200);
    expect(Array.isArray(response.body.data)).toBe(true);
  });

  it('/person/:id (GET) should return a person by ID', async () => {
    const response = await request(app.getHttpServer()).get(`/person/${personId}`);
    
    expect(response.status).toBe(200);
    expect(response.body.data).toHaveProperty('_id', personId);
  });

  it('/person/:id (PUT) should update a person', async () => {
    const updateData = { name: 'Alice Updated', age: 35 };
    const response = await request(app.getHttpServer())
      .put(`/person/${personId}`)
      .send(updateData);
    
    expect(response.status).toBe(200);
    expect(response.body.data.name).toBe('Alice Updated');
  });

  it('/person/:id (DELETE) should delete a person', async () => {
    const response = await request(app.getHttpServer()).delete(`/person/${personId}`);
    
    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('deleted', true);
  });

  it('/person/:id (GET) should return 404 after deletion', async () => {
    const response = await request(app.getHttpServer()).get(`/person/${personId}`);
    
    expect(response.status).toBe(404);
  });
});

```





