# Introduction

## Objectifs

- Identifier les caractéristiques de nestjs
- Installer les outils CLI de nestjs
- Créer un projet

## Description
NestJS est un framework Node.js pour construire des applications backend efficaces, évolutives et maintenables. Il est basé sur TypeScript et s'inspire fortement d'Angular en termes de structure et d'architecture.

### Caractéristiques principales
- Basé sur TypeScript (mais compatible avec JavaScript)
- Architecture modulaire (organisation en modules pour une meilleure scalabilité)
- Utilisation de décorateurs pour structurer les contrôleurs, services, etc.
- Supporte Express et Fastify (pour améliorer les performances)
- Système d’injection de dépendances puissant
- Facilite l'intégration avec des bases de données (via TypeORM, Prisma, Mongoose etc.)
- Middleware, Guards, Pipes et Intercepteurs pour gérer la logique métier et la sécurité

### Pourquoi utiliser NestJS ?
- Idéal pour les API REST et GraphQL
- Convient aux microservices
- Facile à tester et à maintenir grâce à une structure claire
- Scalable pour des projets de grande envergure

## Premier projet

### Installation

Il faut tout d'abord installer les outils en ligne de commande (CLI). l'opérateur `-g` définit une installation globale.

```shell
npm install -g @nestjs/cli
```

Ensuite, nous utilisons la ligne de commande pour générer un nouveau projet.

```shell
nest new <dossier du projet>
```

Il ne reste qu'à lancer l'application,

```shell
cd <dossier du projet>
```
puis
```shell
npm run start:dev
```

Avant de tester dans un navigateur à l'adresse suivante : `http://localhost:3000`.

### Architecture

Voici la structure du projet, toute la logique de notre application réside dans le dossier `src`.

![CleanShot 2025-02-14 at 07.36.20@2x.png](CleanShot 2025-02-14 at 07.36.20@2x.png)

#### main.ts

Il s'agit du fichier chargé de lancer l'application

```typescript
// Importation de NestFactory 
// pour créer une instance de l'application NestJS
import { NestFactory } from '@nestjs/core'; 

// Importation du module principal de l'application
import { AppModule } from './app.module'; 

// Fonction asynchrone qui démarre l'application
async function bootstrap() {

  // Création d'une instance de l'application NestJS 
  // en utilisant AppModule comme module racine
  const app = await NestFactory.create(AppModule);

  // L'application écoute sur un port défini 
  // dans les variables d'environnement (PORT) 
  // ou par défaut sur 3000
  await app.listen(process.env.PORT ?? 3000);
}

// Appelle immédiatement la fonction bootstrap 
// pour démarrer l'application
void bootstrap();

```

#### app.module.ts

Il s'agit du module principal de l'application, celui chargé par `main.ts`. Ce module pourra en importer d'autres afin d'étendre les fonctionnalités de l'application. Cette architecture modulaire est au cœur du fonctionnement de Nestjs.

```typescript
// Importation du décorateur @Module 
// pour définir un module NestJS
import { Module } from '@nestjs/common'; 

// Importation du contrôleur principal de l'application
import { AppController } from './app.controller'; 

// Importation du service principal de l'application
import { AppService } from './app.service'; 

// Définition du module principal de l'application
@Module({

  // Liste des modules importés 
  // (vide ici, mais peut contenir d'autres modules NestJS)
  imports: [], 
  
  // Déclare les contrôleurs qui gèrent les requêtes HTTP
  controllers: [AppController], 
  
  // Déclare les services qui contiennent la logique métier 
  // et peuvent être injectés
  providers: [AppService],
   
})

// Exportation de la classe AppModule, 
// qui est le module racine de l'application
export class AppModule {} 

```

#### app.controller.ts

Le contrôleur reçoit la requête http, transmet l'information aux services et retourne la réponse http. Il ne devrait pas contenir de logique métier, sa seule responsabilité est l'aiguillage et la communication avec les services.

```typescript

// Importation des décorateurs nécessaires 
// pour définir un contrôleur et une route GET
import { Controller, Get } from '@nestjs/common'; 

// Importation du service AppService 
// qui contient la logique métier
import { AppService } from './app.service'; 

// Définition d'un contrôleur dans NestJS
// Déclare cette classe comme un contrôleur 
// et définit le préfixe de route (ici, route racine `/`)
@Controller() 
export class AppController {
  // Injection de dépendance : 
  // AppService est injecté dans le contrôleur 
  // via le constructeur
  constructor(private readonly appService: AppService) {}

  // Définit une route GET sur l'URL racine `/`
  @Get() 
  getHello(): string {
  
    // Appelle la méthode du service et retourne la réponse
    return this.appService.getHello(); 
  }
}
```

#### app.service.ts

Un service est une classe injectable qui est chargée de réaliser un traitement, d'implémenter une partie de la logique métier.

```typescript

// Importation du décorateur Injectable 
// pour indiquer que cette classe peut être injectée
import { Injectable } from '@nestjs/common'; 

// Marque cette classe comme un service 
// injectable dans NestJS
@Injectable() 
export class AppService {

  // Méthode qui retourne une simple chaîne de caractères
  getHello(): string {
    // Réponse envoyée lorsque cette méthode est appelée
    return 'Hello World!'; 
  }
}
```

#### Décorateur

Dans NestJS, les décorateurs sont des fonctions qui permettent d'ajouter des métadonnées aux classes, aux méthodes, aux paramètres et aux propriétés.

Un décorateur s'exécute au moment de la définition d'une classe ou d'une méthode.

Il commence par un `@` et est placé au-dessus de la classe, la méthode ou le paramètre qu'il "décore".


```typescript
function MyDecorator(target: any) {
  console.log("Décorateur exécuté sur :", target);
}

@MyDecorator
class MyClass {}
```

Un décorateur peut également recevoir des arguments. 

```typescript
function MyDecorator(message: string) {
  return function (target: any) {
    console.log(`Décorateur exécuté sur : ${target.name}, 
    Message : ${message}`);
  };
}

@MyDecorator("Hello from MyDecorator!")
class MyClass {}
```

Pour de multiples arguments, il sera judicieux de passer un objet littéral.

```typescript
function MyDecorator(settings) {
  return function (target: any) {
    console.log(`Décorateur exécuté sur : ${target.name}, 
    Message : ${settings.message} from ${settings.from}`);
  };
}

@MyDecorator({message: 'Hello', from: 'World})
class MyClass {}
```

##### Les principaux décorateurs de NestJS

| Décorateur          | Type        | Description |
|---------------------|------------|-------------|
| `@Controller()`    | Classe     | Définit une classe comme un contrôleur pour gérer les routes HTTP. |
| `@Get()`          | Méthode    | Gère une requête HTTP `GET`. |
| `@Post()`         | Méthode    | Gère une requête HTTP `POST`. |
| `@Put()`          | Méthode    | Gère une requête HTTP `PUT`. |
| `@Delete()`       | Méthode    | Gère une requête HTTP `DELETE`. |
| `@Patch()`        | Méthode    | Gère une requête HTTP `PATCH`. |
| `@Param()`        | Paramètre  | Récupère un paramètre de l’URL (`:id`). |
| `@Body()`         | Paramètre  | Récupère le **corps** de la requête (`body`). |
| `@Query()`        | Paramètre  | Récupère les **paramètres de requête** (`?key=value`). |
| `@Headers()`      | Paramètre  | Récupère les **en-têtes HTTP**. |
| `@Req()`          | Paramètre  | Récupère l’objet **Request** (`express` ou `fastify`). |
| `@Res()`          | Paramètre  | Récupère l’objet **Response** (`express` ou `fastify`). |
| `@HttpCode()`     | Méthode    | Définit le **code de réponse HTTP** (`201`, `400`, etc.). |
| `@Injectable()`   | Classe     | Marque une classe comme **injectable** (service, repository, etc.). |
| `@Inject()`       | Propriété  | Injecte une **dépendance manuellement**. |
| `@UseGuards()`    | Méthode/Classe | Protège une route avec un **Guard** (`AuthGuard`). |
| `@UseInterceptors()` | Méthode/Classe | Transforme/modifie la réponse (logs, cache, etc.). |
| `@UseFilters()`   | Méthode/Classe | Capture et gère les erreurs (`ExceptionFilters`). |
| `@UsePipes()`     | Méthode/Classe | Applique une **validation** (`ValidationPipe`). |
| `@SetMetadata()`  | Méthode/Classe | Ajoute des **métadonnées personnalisées** pour les Guards ou Interceptors. |
| `@Module()`       | Classe     | Définit un **module** (`AppModule`, `UserModule`, etc.). |
| `@Global()`       | Classe     | Rend un module **global** (accessible partout sans import explicite). |

