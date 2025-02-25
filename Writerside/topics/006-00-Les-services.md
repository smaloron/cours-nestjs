# Les services

## L'injection de dépendance

NestJS utilise un conteneur d’injection de dépendances qui permet de fournir et injecter automatiquement des classes/services dans d'autres classes sans avoir besoin de les instancier manuellement.

**Concepts clés :**
- Provider : Une classe qui peut être injectée dans d'autres classes.
- Injectable : Un décorateur (`@Injectable()`) qui indique qu'un service peut être injecté.
- Module : Un regroupement de fonctionnalités (services, contrôleurs, etc.).
- Injection automatique : NestJS gère automatiquement la création et l’injection des dépendances.

### Exemple d'injection de dépendance

#### Le service

Un service est une classe décorée par `@Injectable()` et qui possède des méthodes ou des propriétés publiques utilisables pour d'autres classes.

```typescript
// person/tax.service.ts

import { Injectable } from '@nestjs/common';

// Décorateur qui rend cette classe injectable
@Injectable() 
export class TaxService {

  readonly taxMultiplier: number = 1.2;

  getGrossPrice(netPrice: number): number {
    return netPrice * taxMultiplier;
  }
}
```

#### La déclaration dans un module

Pour que le service soit injectable, il faut les déclarer dabs le tableau `providers` d'un module.

```typescript
import { Module } from '@nestjs/common';
import { PersonController } from './person.controller';
import { PersonProvider } from './tax.service';

@Module({
  controllers: [PersonController],
  // Déclaration du service
  providers: [TaxService]
})
export class PersonModule {}
```

#### Utilisation dans un contrôleur

Nous n'avons plus qu'à injecter le service et l'utiliser dans un contrôleur par exemple.

```typescript
import { Controller, Get, 
         ParseFloatPipe 
} from '@nestjs/common';

import { TaxService } from './tax.service';

@Controller('tax')
export class UserController {

  // Injection du service dans le constructeur
  constructor(private readonly taxService: TaxService) {}

  @Get()
  getTax(@Param('netPrice', ParseFloatPipe): number {
    return this.taxService.getGrossPrice(netPrice);
  }
}
```

## Un peu de vocabulaire

Les diverses sources d'information sur NestJS utilisent souvent les termes de `provider`, `services` et `repository`.

### Provider
Un provider est un terme générique en NestJS qui désigne toute classe pouvant être injectée dans une autre. Cela inclut les services, repositories, factories, helpers, etc.

### Repository
Un repository est un provider spécifique qui gère l'accès aux données. En général, il est utilisé pour interagir avec une base de données via TypeORM, Mongoose ou Prisma.

### Service
Un service est une classe qui encapsule la logique métier. Il est généralement injecté dans des contrôleurs pour exécuter des actions spécifiques. Les services peuvent aussi utiliser d'autres providers, comme des repositories ou des API externes.

## Création d'un repository

Nous allons créer un repository pour simuler une connexion à une base de données.

La commande suivante génère une classe `PersonService` dans le dossier `person`. Elle référence également cette nouvelle classe dans le tableau `providers` de `PersonModule`.

```shell
nest generate service person
```

Renommons cette classe `PersonRepository` et le fichier `person.repository.ts`(sans oublier de changer l'import dans `person.module.ts`)

```typescript
// person/person.repository.ts

import { Injectable } from '@nestjs/common';

@Injectable()
export class PersonRepository {}
```

```typescript
import { Module } from '@nestjs/common';
import { PersonController } from './person.controller';
import { PersonRepository } from './person.repository';

@Module({
  controllers: [PersonController],
  providers: [PersonRepository,]
})
export class PersonModule {}

```

### Interface

Dans `person.repository.ts`, nous définissons une interface pour nos personnes.

```typescript
import { Injectable } from '@nestjs/common';

export interface PersonInterface {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  age: number;
  company?: string;
  jobTitle?: string;
}

@Injectable()
export class PersonRepository {}
```

### Modification du DTO

Ajoutons une propriété `id` optionnelle au DTO pour gérer l'ajout d'une nouvelle personne.

```typescript
// dans person/person.dto.ts

export class CreatePersonDto {

  @IsOptional()
  @IsInt()
  id: number
 
 // ...suite de la classe 
}
```

### Données de test

Toujours dans `person.repository.ts`, nous définissons un tableau d'objet qui nous servira à simuler un appel à une base de données.

```typescript
// dans person.repository.ts

@Injectable()
export class PersonRepository {
  private persons: PersonInterface[] = [
    {
      id: 1, firstName: 'Ada', lastName: 'Lovelace',
      age: 30, email: 'ada@algo.com'
    },
    {
      id: 2, firstName: 'Grace', lastName: 'Hopper',
      age: 40, email: 'grace.hopper@algo.com'
    }
  ];
}
```

### Première méthode : findAll

Cette méthode retournera toutes les données du tableau `persons`. Cette opération n'est pas asynchrone, mais l'appel à une base de données le sera, pour les besoins de la simulation, nous définirons donc cette méthode comme étant asynchrone.

Le retour de la méthode `PersonInterface[]` est enrobé dans une promesse puisque la fonction est asynchrone.

```typescript

async findAll(): Promise<PersonInterface[]>{
    return this.persons;
}
```

#### Le contrôleur

Modifions ensuite le contrôleur.

Tout d'abord injectons le service dans un constructeur

```typescript
import { PersonRepository } from './person.repository';

constructor(
    private personRepository: PersonRepository
) {}
```

Ensuite, modifions la méthode `getAll` du contrôleur.

- La méthode devient asynchrone.
- Le retour est enrobé dans une promesse.
- Les données sont obtenues par un appel à la méthode `findAll` de `PersonRepository`.
- Comme cet appel est asynchrone, il faut résoudre la promesse,avec `await` (ou en utilisant la fonction `then`et en passant une fonction de callback).

```typescript
async getAll(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number
  ):Promise<ReturnMessageInterface>
  {
    const persons = await this.personRepository.findAll()
    
    return {
      action: actions.READ,
      message: `Liste de toutes les personnes page ${page}`,
      success: true,
      data: persons
    };
  }
```

### Méthode findOneById

```typescript
async findOneById(id: number): Promise<PersonInterface> 
{
  // Recherche d'une personne dans le tableau  
  const person = this.persons.find(person => person.id === id);
  
  // Exception si aucune personne trouvée
  if(!person) {
    throw new NotFoundException(`Aucune personne avec l'id ${id}`);
  }
  
  return person;
}
```

#### Le contrôleur {id="le-controleur_1"}

```typescript
@Get(':id')
  async getOne(
    @Param('id', new ParseIntPipe()) id: number
  ):Promise<ReturnMessageInterface>
  {
    const person = await this.personRepository.findOneById(id);
    return {
      action: actions.READ,
      message: `Une personne dont l'id est ${id}`,
      success: true,
      data: person
    };
  }
```

### La méthode insert

Pour l'insertion, nous récupérons un objet de type `CreatePersonDto` qui contient les données. 

Nous lui ajoutons un id (le timestamp en ms).

```typescript
  async insert(
        person: CreatePersonDto
  ): Promise<PersonInterface> 
  {
    // Ajout d'un id
    person.id = new Date().getTime();
    // Ajout de la personne au tableau
    this.persons.push(person);

    return person;
  }
```

#### Le contrôleur {id="le-controleur_2"}

```typescript
@Post()
async insert(
    @Body() person: any
  ):Promise<ReturnMessageInterface>
  {
    const savedPerson = await this.personRepository.insert(person);
    return {
      action: actions.INSERT,
      message: `Ajout d'une personne`,
      success: true,
      data: savedPerson
    };
}
```

### La méthode delete

```typescript
async delete(id: number): Promise<boolean> {
  // index de la personne en fonction de son id
  let index = this.persons.findIndex(
    person => person.id === id
  );
  
  // Exception si non trouvé
  if (index == -1) {
    throw new NotFoundException(`Aucune personne avec l'id ${id}`);
  }

  // Suppression dans le tableau
  this.persons.splice(index, 1);
  
  return true;
}
```

#### Le contrôleur {id="le-controleur_3"}

```typescript
@Delete(':id')
async delete(
    @Param('id', new ParseIntPipe()) id: number,
): Promise<ReturnMessageInterface>
{
    const result:boolean = await this.personRepository.delete(id);
    return {
      action: actions.DELETE,
      message: `Suppression d'une personne 
                dont l'id est ${id}`,
      success: result,
      data: null
    };
}
```

### La méthode replace

```typescript
async replace(
    id: number, 
    person: CreatePersonDto
): Promise<PersonInterface> 
{
  let index = this.persons.findIndex(
    person => person.id === id
  );
  if (index == -1) {
    throw new NotFoundException(`Aucune personne avec l'id ${id}`);
  }
  // Ajout de l'id au DTO
  person.id = Number(id);
  
  // Remplacement de la personne
  this.persons[index]= person;
  
  return person;
}
```

#### Le contrôleur {id="le-controleur_4"}

````typescript
@Put(':id')
async replace(
    @Param('id', new ParseIntPipe()) id: number,
    @Body() person: CreatePersonDto
):Promise<ReturnMessageInterface>
{
    const replacedPerson = await this.personRepository
                                     .replace(id, person);
    return {
      action: actions.UPDATE,
      message: `Remplacement d'une personne`,
      success: true,
      data: replacedPerson
    };
}
````

### La méthode update

```typescript
async update(
    id: number, 
    person: UpdatePersonDto
): Promise<PersonInterface> 
{
    // Recherche de la personne à modifier
    let found = await this.findOneById(id);
    
    if (!found) {
      throw new NotFoundException(`Aucune personne avec l'id ${id}`);
    }

    // Fusion de l'objet found avec le DTO
    for (const key in found) {
      if (key in person) {
        found[key] = person[key];
      }
    }

    return found;
}
```

#### Le contrôleur {id="le-controleur_5"}

````typescript
@Patch(':id')
async update(
    @Param('id', new ParseIntPipe()) id: number,
    @Body() person: UpdatePersonDto
): Promise<ReturnMessageInterface>
{
    const updatedPerson = await this.personRepository.update(id, person);
    return {
      action: actions.UPDATE,
      message: `Modification d'une personne`,
      success: true,
      data: updatedPerson
    };
}
````

## Exercice

Faire de même pour books :

- Créer une classe `BookRepository`.
- Modifier le contrôleur `BookController`.
- Tester l'api.

## Exporter un module

Il arrive qu'un module ait besoin des Ressources d'un autre module pour travailler. Dans ce cas, nous pouvons exporter un élément d'un module afin de pouvoir l'importer ailleurs.

### Un exemple

Commençons par créer deux modules, `UserModule` et `AuthModule`.

```shell
nest generate module user
```

```shell
nest generate module auth
```

Ajoutons également une interface pour l'authentification.

```typescript
// dans common/interfaces/common.intefaces.ts

export interface Credentials {
  username: string;
  password: string;
}

```

#### UserModule

Dans `UserModule`, nous allons créer un service `UserService`, ce service devra être exporté car `AuthModule` en aura besoin.

```typescript
// user/user.service.ts
import { Injectable } from '@nestjs/common';
import { Credentials } from '../common/interfaces/common.interfaces';

@Injectable()
export class UserService {
  async findUserByEmail(
    email: string
  ): Promise<Credentials> {
    return {username: email, password: '123'};
  }
}
```

```typescript
// user/user.module.ts

import { Module } from '@nestjs/common';
import { UserService } from './user.service';

@Module({
  providers: [UserService],
  // Export de UserService 
  // afin de le rendre disponible
  // pour les autres modules
  exports: [UserService]
})
export class UserModule {}
```

#### AuthModule

Dans `AuthModule`, il faut importer `UserModule` afin d'utiliser une de ses ressources comme provider.

```typescript
// auth/auth.module.ts

import { Module } from '@nestjs/common';
import { UserService } from '../user/user.service';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { UserModule } from '../user/user.module';

@Module({
  // Importation de UserModule
  imports: [UserModule],
  // Pour rendre UserService disponible
  providers: [UserService, AuthService],
  controllers: [AuthController]
})
export class AuthModule {}
```

Ici `UserService` est injecté dans `AuthService`

```typescript
// auth/auth.service.ts

import { Injectable } from '@nestjs/common';
import { UserService } from '../user/user.service';
import { Credentials } from '../common/interfaces/common.interfaces';


@Injectable()
export class AuthService {
  constructor(private readonly usersService: UserService) {}

  async validateUser(
    credentials: Credentials
 ): Promise<boolean> 
 {
    const user = await this
                 .usersService
                 .findUserByEmail(credentials.username);
    
    return user 
           && user.password === credentials.password;
  }
}
```

Et enfin, nous pouvons créer un contrôleur pour tester ce partage de ressources.

```typescript
// auth/auth.controller.ts

mport { Body, Controller, Param, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
import { Credentials } from '../common/interfaces/common.interfaces';

@Controller('auth')
export class AuthController {

  constructor(
    private readonly authService: AuthService
  ) {}


  @Post('login')
  async login(
      @Body()
      credentials: Credentials
  ): Promise<any>
    {
    const success: boolean = await this
      .authService
      .validateUser(credentials);

    return {
      success
    }

  }

}
```

Et un test

```
### Test de l'authentification

POST http://localhost:3000/auth/login
Accept: application/json
Content-Type: application/json

{
  "username": "joe",
  "password": "123"
}
```

