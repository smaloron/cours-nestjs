# La validation des requêtes

## Pourquoi et comment valider

Lorsqu'un utilisateur envoie des données dans le corps d'une requête (body), ces données peuvent être incomplètes, incorrectes ou malveillantes. Valider @Body() permet de s'assurer que les données respectent les règles définies avant qu'elles ne soient traitées par ton application.

Pour cela, nous avons besoins de deux choses :

- Une classe chargée de recevoir les données, on appelle souvent de telles classes DTO (Data Transfer Object).
- Une classe chargée de valider les DTO

### Installation

```shell
npm install --save class-validator class-tranformer
```

### Un DTO

Un DTO n'est rien d'autre qu'une classe qui ne possède que des propriétés publiques.

```typescript
// person/person.dto.ts

export class CreatePersonDto {

  firstName: string;

  lastName: string;
  
  age: number;

  email: string;
}
```

Ajoutons des contraintes de validation sous la forme de décorateurs

```typescript
// person/person.dto.ts

import { IsString, IsEmail, 
         IsNotEmpty, MinLength, 
         MaxLength, IsNumber 
       } from 'class-validator';

export class CreatePersonDto {

  @IsNotEmpty()
  @IsString()
  @MaxLength(20)
  @MinLength(2)
  firstName: string;

  @IsNotEmpty()
  @IsString()
  @MaxLength(20)
  @MinLength(2)
  lastName: string;
  
  @IsNumber()
  age: number;
  
  @IsEmail()
  email: string;
}
```

### Utilisation du DTO dans un contrôleur

Il suffit de typer l'argument lié à `@body` avec le DTO.

Modifions la méthode insert pour utiliser notre DTO.

```typescript
import { CreatePersonDto } from './person.dto.create.ts';

  @Post()
  insert(
    @Body() dto: CreatePersonDto
  ):any
  {
    return {message: 'succès', data: dto};
  }
```

### Validation Pipe

La validation s'effectue via un `Pipe`. Il s'agit d'intercepter la requête et de valider les données avant qu'elles n'atteignent le contrôleur.

#### Application globale

```typescript
// main.ts

import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Activation globale de la validation
  app.useGlobalPipes(new ValidationPipe());

  await app.listen(3000);
}
bootstrap();
```

#### Application sur une action de contrôleur

```typescript
import { Controller, Post, 
         Body, UsePipes, 
         ValidationPipe 
} from '@nestjs/common';

import { CreatePersonDto } from './person.dto.ts';

  @Post()
  // Activation de la validation uniquement sur cette route
  @UsePipes(new ValidationPipe()) 
  insert(
    @Body() person: CreatePersonDto
  ):any
  {
    return person;
  }
```

### Tests

Tester l'envoi de données partielles ou incorrectes

- Envoyer des données absentes dans le DTO (une clef job par exemple)
- Omettre la clef email
- Omettre la clef lastName
- Envoyer un email invalide
- Envoyer un texte pour l'âge

## Options de validation avancées

### Rendre la validation plus stricte

```typescript
// main.ts

app.useGlobalPipes(
  new ValidationPipe({
    // Supprime les propriétés non définies dans le DTO
    whitelist: true,  
    
    // Génère une erreur si des propriétés 
    // inconnues sont envoyées
    forbidNonWhitelisted: true,  
    
    // Transforme les données 
    // en type défini dans le DTO
    transform: true,  
  }),
);
```

Refaire les tests précédents et constater le résultat

### Validation conditionnelle

```typescript
// person.dto.ts

  @IsOptional()
  @IsString()
  company: string;
  
  // On ne valide jonTitle que si
  // la clef company existe
  @ValidateIf(object => object.company)
  @IsString()
  jobTitle: string;
```

### Message d'erreur personnalisé

Il suffit de passer un objet littéral avec une clef message sans les arguments du décorateur de validation.

```typescript
@IsEmail({message: "l'adresse email doit être valide"})
  email: string;
```

### Validation de tableaux ou d'objets imbriqués

- `ValidateNested({ each: true })` assure que chaque élément du tableau est valide.
- `Type(() => AddressDto)` est nécessaire pour convertir addresses en instances AddressDto.

```typescript
// person.dto.ts

import { Type } from 'class-transformer';
import { IsArray, ValidateNested, IsString } from 'class-validator';

class AddressDto {
  @IsString()
  street: string;

  @IsString()
  city: string;
}

export class CreateUserWithAddressesDto {
  @IsString()
  name: string;

  @IsArray()
  // Valider chaque élément du tableau
  @ValidateNested({ each: true }) 
  // Transformer les objets en instances de AddressDto
  @Type(() => AddressDto) 
  addresses: AddressDto[];
}
```

### Éviter la duplication du code

Le DTO `CreatePersonDTO` est parfait pour l'insertion, mais pour une mise à jour, il est possible, voir probable que nous ne recevions qu'une partie des données.

Nous pourrions créer un autre DTO, `UpdateUserDTO` par exemple et rendre optionnels les propriétés de cette nouvelle classe.

Cependant, cette approche nous oblige à dupliquer du code, ce qui n'est jamais une bonne idée.

Une autre solution consiste à utiliser les `Mapped Types`. Cela consiste à hériter des propriétés d'un DTO en ajoutant un décorateur `@IsOptional` sur chacune d'entre elles.

```shell
npm install @nestjs/mapped-types
```

```typescript
// person.dto.ts

// Ce DTO reprend toutes les propriétés de CreatePersonDto
// mais les rend optionnelles
export class UpdatePersonDto extends PartialType(CreatePersonDto){}
```

Nous pouvons donc désormais modifier les routes de mise à jour (`PUT` et `PATCH`)

```typescript
@Put(':id')
  replace(
    @Param('id') id: number,
    @Body() person: CreatePersonDto
  ):any
  {
    return person;
  }

  @Patch(':id')
  update(
    @Param('id') id: number,
    @Body() person: UpdatePersonDto
  ): any
  {
    return person;
  }
```

## Les retours

Dans un souci d'harmonisation de notre API, il est judicieux de typer les valeurs de retour. De cette façon, l'API réagira de la même façon et les développeurs qui consomment cette API apprécieront cette cohérence.

Pour cela nous définirons une interface que nous placerons dans un dossier `common` car cette ressource a vocation à être partagée par tous les modules de notre application.

```typescript
// common/interfaces/common.interfaces.ts

export enum actions {
  READ = 'READ',
  UPDATE = 'UPDATE',
  DELETE = 'DELETE',
  INSERT = 'INSERT',
}

export interface ReturnMessageInterface {
  message?: string;
  action: actions;
  success: boolean;
  data?: any;
}
```

Puis, nous modifions le code de notre contrôleur

```typescript
import { Body, Controller, Delete, 
         Get, Param, Patch, 
         Post, Put, Query, Headers 
} from '@nestjs/common';

import { CreatePersonDto, 
         UpdatePersonDto 
} from './person.dto';

import { 
    actions, ReturnMessageInterface 
} from '../common/interfaces/common.interfaces'

@Controller('person')
export class PersonController {

  @Get()
  getAll(
    @Query('page')page:number = 1
  ):ReturnMessageInterface
  {
    return {
      action: actions.READ,
      message: `Liste de toutes les personnes page ${page}`,
      success: true,
      data: []
    };
  }

  @Get('search')
  search(@Query('term') term: string
  ):ReturnMessageInterface {
    return {
      action: actions.READ,
      message: `recherche sur ${term}`,
      success: true,
      data: []
    };
  }

  @Get('with-token')
  withToken(
    // récupération d'un en-tête spécifique
    @Headers('x-token') token:string
  ): ReturnMessageInterface
  {
    return {
      action: actions.READ,
      message: `Réception d'un token`,
      success: true,
      data: {token: token}
    };
  }

  @Get('with-all-headers')
  withAllHeaders(
    // récupération de tous les en-têtes
    // Record est un objet TypeScript qui se comporte
    // comme un Map Java (tableau associatif)
    @Headers() headers: Record<string, string>
  ): ReturnMessageInterface
  {
    return {
      action: actions.READ,
      message: `Récetion des en-têtes`,
      success: true,
      data: {headers: headers}
    };
  }

  @Get(':id')
  getOne(
    @Param('id(\\d+)') id: string
  ):ReturnMessageInterface
  {
    return {
      action: actions.READ,
      message: `Une personne dont l'id est ${id}`,
      success: true,
      data: []
    };
  }

  @Post()
  insert(
    @Body() person: CreatePersonDto
  ):ReturnMessageInterface
  {
    return {
      action: actions.INSERT,
      message: `Ajout d'une personne`,
      success: true,
      data: person
    };
  }

  @Put(':id')
  replace(
    @Param('id') id: number,
    @Body() person: CreatePersonDto
  ):ReturnMessageInterface
  {
    return {
      action: actions.UPDATE,
      message: `Remplacement d'une personne`,
      success: true,
      data: person
    };
  }

  @Patch(':id')
  update(
    @Param('id') id: number,
    @Body() person: UpdatePersonDto
  ): ReturnMessageInterface
  {
    return {
      action: actions.UPDATE,
      message: `Modification d'une personne`,
      success: true,
      data: person
    };
  }

  @Delete(':id')
  delete(
    @Param('id') id: number
  ): ReturnMessageInterface
  {
    return {
      action: actions.DELETE,
      message: `Suppression d'une personne 
                dont l'id est ${id}`,
      success: true,
      data: null
    };
  }
}

```

## Valider des paramètres et des querystring

La validation obéit aux mêmes règles que pour le corps de la requête (Body). Il est toutefois possible de simplifier un peu, les paramètres étant par définition scalaires. 

### Validation simple

Ici, pour un id, nous utilisons une classe `ParseIntPipe` (qu'il faudra importer) pour valider une saisie numérique entière.

```typescript
// person/person.controller.ts

@Get(':id')
  getOne(
    @Param('id', ParseIntPipe) id: string
  ):ReturnMessageInterface
  {
    return {
      action: actions.READ,
      message: `Une personne dont l'id est ${id}`,
      success: true,
      data: []
    };
  }
```

Les pipes disponibles sont les suivants :
- `ParseIntPipe`
- `ParseFloatPipe`
- `ParseBoolPipe`
- `ParseDatePipe`
- `ParseFilePipe`
- `ParseArrayPipe`
- `ParseUUIDPipe`

### Validation standard

Pour ajouter des règles de validation aux paramètres, nous pouvons toujours utiliser un DTO.

Ici outre le fait que l'id doit être un entier, nous testons que sa valeur est supérieure à zéro.

```typescript
// person/person.dto

import { IsInt, Min } from 'class-validator';

export class PersonParamDto {
  @IsInt({ message: 'ID doite être un entier' })
  @Min(1, { message: 'ID doit être supérieur ou égal à 1' })
  id: number;
}
```

Puis utiliser ce DTO pour typer le paramètre

```typescript
// person/person.controller.ts

@Get(':id')
  getOne(
    @Param('id') id: PersonParamDto
  ):ReturnMessageInterface
  {
    return {
      action: actions.READ,
      message: `Une personne dont l'id est ${id}`,
      success: true,
      data: []
    };
  }
```

### Valider la `QueryString`

Nous pouvons faire de même pour valider les élements du `QueryString`.

#### De manière simple

```typescript
// person/person.dto.ts

@Get()
  getAll(
    @Query( 'page', 
            // valeur par défaut
            new DefaultValuePipe(1), 
            ParseIntPipe
          ) page: number
  ):ReturnMessageInterface
  {
    return {
      action: actions.READ,
      message: `Liste de toutes les personnes page ${page}`,
      success: true,
      data: []
    };
  }
```

#### Avec un DTO

```typescript
// person/person.dto.ts

export class PersonQueryDto {
  @IsOptional()
  @IsInt({ message: 'La page doit être un entier' })
  @Min(1, { message: 'La page doit être supérieure ou égale à 1' })
  // Conversion en nombre
  @Type(() => Number)  
  page?: number;

  @IsOptional()
  @IsString({ message: 'La recherche doit être un texte' })
  @Length(3, 50, 
    { message: 'La recherche doit contenir entre 3 et 50 caractères' }
  )
  term?: string;
}
```

```typescript
// person/person.dto.ts

@Get()
  getAll(
    @Query() query: PersonQueryDto
  ):ReturnMessageInterface
  {
    return {
      action: actions.READ,
      message: `Liste de toutes les personnes page ${query.page}`,
      success: true,
      data: []
    };
  }
```

## Exercice

Implémenter la validation sur `BookModule` :

- Créer un DTO avec des règles de validation.
- Utiliser ce DTO dans `BookController`.
- Valider également les données `@Param` et `@Query`.
- Utiliser `ReturnMessageInterface` pour harmoniser les réponses de l'API.

