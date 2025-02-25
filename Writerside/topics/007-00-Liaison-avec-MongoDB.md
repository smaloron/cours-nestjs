# NestJS et MongoDB

Nous connaissons les ORM qui facilitent l'exploitation une base de données relationnelle dans le code d'une application. 

MongoDB dispose également d'outils similaires. On ne parle pas ici d'ORM puisqu'il n'est pas question de base de données relationnelles, le terme approprié en ce cas est ODM pour Object Document Mapper. 

Le plus populaire de ses outils, se nomme Mongoose, c'est donc lui que nous allons utiliser.

## Installation

Tout d'abord installons `Mongoose` et son support pour `NestJS`.

```shell
npm install --save @nestjs/mongoose mongoose
```

Il nous faut ensuite un serveur `MongoDB`, nous utiliserons `Docker` pour l'installer localement.

```yaml
# docker-compose
services:
  mongodb:
    image: mongo:latest
    container_name: mongo-container
    restart: always
    ports:
      - "27025:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: 123
    volumes:
      - mongodb_data:/data/db
      - ./data:/shared

volumes:
  mongodb_data:
```

## Configuration de la connexion

Pour configurer la connexion, nous utiliserons des variables d'environnement sur le serveur d'exploitation. Cette pratique évite dle stockage d'informations sensibles dans le code source de l'application et permet la modification de la configuration sans nouveau déploiement.

Toutefois, sur les ordinateurs de développement, il est d'usage de recourir à un fichier `.env` qui simulera ces variables d'environnement. 

Un tel fichier doit être ajouté dans `.gitignore` car il pourrait contenir des informations sensibles.

Enregistrons un fichier `.env` à la racine du projet.

```
PORT=3000
MONGO_URI=mongodb://admin:123@localhost:2725/formation
```

Pour charger ce fichier, nous avons besoin d'un nouveau module (`ConfigModule`) qu'il faut télécharger.

```shell
npm install --save @nestjs/config
```

Ensuite dans `AppModule`, nous importons `ConfigModule` comme suit :

```typescript
// app.module.ts

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

@Module({
  imports: [
    ConfigModule.forRoot({
        // ConfigModule sera accessible globalement
        // pour tous les modules de l'application
        // sans avoir besoin de l'importer
        isGlobal: true
    }),
  ],
})
export class AppModule {}
```

### Que signifie forRoot ?

Dans NestJS, la méthode forRoot() est une convention utilisée pour configurer et initialiser un module avec des paramètres globaux. Elle est souvent utilisée dans les modules dynamiques pour fournir une configuration à l'ensemble de l'application.

Il existe une autre fonction `forfeature` qui permet de fournir une configuration spécifique pour un seul module.

<!--
### Valider les variables d’environnement avec Joi

Pour éviter les erreurs dues à des variables mal définies, nous utiliserons Joi.

```
npm install --save joi
```

```typescript
// app.module.ts

import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import Joi from 'joi';

@Module({
  imports: [
    ConfigModule.forRoot({
        isGlobal: true,
        validationSchema: Joi.object({
            PORT: Joi.number().default(3000),
            DATABASE_URL: Joi.string().required(),
        }),
    }),
  ],
})
export class AppModule {}
```
-->

### Configuration de Mongoose

Il ne reste plus qu'à passer à Mongoose l'URI de notre serveur MongoDB.

```typescript
// app.module.ts

import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PersonModule } from './person/person.module';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';

@Module({
  imports: [
    PersonModule,
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    MongooseModule.forRoot(
      process.env.MONGO_URI || 'mongodb://localhost:27017/formation'
    ),
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
```

## Découverte de Mongoose

Mongoose est un ODM qui utilise les concepts de `schema` et de `model`.

### Le schéma

Un Schéma en Mongoose est une structure qui définit la forme des documents stockés dans une collection MongoDB. Il permet de spécifier :

- Les champs d’un document.
- Le type de données de chaque champ.
- Les contraintes (ex: obligatoire, valeur par défaut, validation).
- Les relations avec d'autres documents.
- Des méthodes personnalisées.

Le schéma ne représente pas directement une collection MongoDB, il est juste une définition de structure, de contraintes et d'éventuelles règles de traitement.

Il est possible qu'une même collection soit régie par plusieurs schemas, il est également possible, mais plus rare, qu'un schéma soit appliqué à plusieurs collections.

### Le modèle

Un modèle est une classe qui applique un schéma à une collection MongoDB. Le modèle expose également des méthodes d'extraction et de manipulation des données (lecture, insertion, suppression, modification). En cela, le modèle offre les services d'un DAO.

### Le schéma est-il une incohérence ?

MongoDB est une base de données NoSQL qui se distingue des bases relationnelles par son absence de schéma strict. Contrairement aux bases SQL (comme MySQL ou PostgreSQL) où les structures sont rigides, MongoDB permet de stocker des documents sans format prédéfini.

**Alors, pourquoi Mongoose impose-t-il un schéma alors que MongoDB est "sans schéma" ?**

##### Les limites de la flexibilité totale

MongoDB est schéma-flexible, ce qui signifie que chaque document dans une collection peut avoir une structure différente. Cela donne beaucoup de flexibilité, mais cela peut aussi poser des problèmes :

- Incohérences : Sans structure définie, des erreurs peuvent apparaître (ex: certains documents ont un champ age, d'autres non).
- Validations manuelles : Il faut vérifier les types et les contraintes soi-même.
- Difficulté de maintenance : Dans un projet avec plusieurs développeurs, l'absence de structure claire peut mener au chaos.

**C’est là que Mongoose intervient !**

#### Mongoose, un compromis entre flexibilité et structure

Mongoose introduit des schémas pour donner une structure aux données sans perdre les avantages de MongoDB. Voici pourquoi :

###### ✅ Meilleure organisation des données
Un schéma garantit que chaque document suit une structure prévisible.

Ex: Si un champ email est obligatoire, Mongoose le force.

###### ✅ Validation automatique des données

Il n'est plus nécessaire d'écrire du code de validation manuel.

Ex: age: { type: Number, min: 18 } empêche d’enregistrer un âge < 18.
###### ✅ Gestion des relations entre documents

Même si MongoDB ne gère pas directement les relations comme SQL, Mongoose permet de créer des références (ref) et des populations (populate()).
###### ✅ Middleware & Hooks

Avant d'enregistrer un document (pre-save hook), on peut exécuter du code, par exemple pour chiffrer un mot de passe.

###### ✅ Facilite l’interaction avec MongoDB

Mongoose offre une API puissante pour interagir avec MongoDB de manière plus propre et organisée.

###### ✅ Conserve la flexibilité

Le schéma ignore les champs de la collection qui ne sont pas spécifiés. Il est donc possible de voir des schémas différents appliqués à une même collection.

Par exemple une collection `products` qui stocke les informations sur des produits et des schéms différents qui forcent la présence de certains champs en fonction du type de produits :

- La taille et la matière pour des vêtements.
- La puissance de la motorisation pour un véhicule.
- La quantité de RAM, le type de processeur et ta taille du disque dur pour un ordinateur.

### Mise en place avec NestJS

#### Création du schéma

Il se passe plusieurs choses ici :

- Création d'une classe `Person`, décorée avec `@Schema` qui définit les propriétés du schéma.
- Création d'un `PersonDocument` qui fusionne les champs de `Person` avec ceux du document de base de Mongoose (_id, createdAt et updatedAt)
- Création d'une instance `PersonSchema` à partir de `Person`.

````typescript
// person/person.schema.ts

import { Schema, SchemaFactory } from '@nestjs/mongoose';
import { Prop } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

// Définition des champs 
// et des contraintes Schéma
@Schema()
export class Person {
  @Prop({ required: true })
  firstName: string;

  @Prop({ required: true })
  lastName: string;

  @Prop({ required: true })
  age: number;

  @Prop({ required: true })
  email: string;

  @Prop()
  company: string;

  @Prop()
  jobTitle: string;
}

// Création du document, HydratedDocument
// fusionne les champs du schéma avec ceux
// du document par défaut de Mongoose
// (_id, createdAt, et updatedAt)
export type PersonDocument = HydratedDocument<Person>;

// Création d'un schéma Mongoose à partir de la définition
export const PersonSchema = SchemaFactory.createForClass(Person);
````

#### Importation dans un module

L'importation de `MongooseModule` a besoin d'une configuration. Il faut donc utiliser la fonction `forFeature` pour passer ces éléments de configuration qui sont :

- `name` : le nom du modèle
- `schema`: le schéma à appliquer 
- `collection` : le nom de la collection (facultatif, par défaut ce sera le nom du modèle au pluriel et en minuscule).

```typescript
// person/person.module.ts

import { Module } from '@nestjs/common';
import { PersonController } from './person.controller';
import { PersonRepository } from './person.repository';
import { MongooseModule } from '@nestjs/mongoose';
import { PersonSchema } from '../person.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: 'Person', schema: PersonSchema }
    ])
  ],
  controllers: [PersonController],
  providers: [PersonRepository,]
})
export class PersonModule {}

```

#### Injection du modèle dans une classe

Pour utiliser le modèle, il faut l'injecter, soit dans un contrôleur ou mieux dans une classe provider telles que notre repository. 

L'injection s'effectue dans le constructeur, elle est décorée par `@InjectModel` qui admet en argument le nom du modèle tel que définit dans l'importation de `MongooseModule`.

Le modèle est de type `Model`, mais il faut préciser le document qui doit s'appliquer (`Model<PersonDocument>`).

````typescript
// person/person.repository

constructor(
    @InjectModel('Person') private PersonModel:Model<PersonDocument>
  ) {}

````

### Utilisation des méthodes du modèle

Un modèle Mongoose expose des méthodes statiques qui permettent de requêter sur une collection.

| Catégorie    | Méthode                    | Description |
|-------------|----------------------------|------------|
| **Lecture (Read)** | `find(query)` | Récupère plusieurs documents correspondant à la requête. |
|  | `findOne(query)` | Récupère un seul document correspondant à la requête. |
|  | `findById(id)` | Récupère un document par son `_id`. |
| **Création (Create)** | `create(data)` | Ajoute un nouveau document dans la collection. |
| **Mise à jour (Update)** | `updateOne(query, updateData)` | Met à jour un seul document correspondant à la requête. |
|  | `updateMany(query, updateData)` | Met à jour plusieurs documents correspondant à la requête. |
|  | `findByIdAndUpdate(id, updateData, options)` | Met à jour un document par son `_id` et retourne l'ancien ou le nouveau document selon l'option `{ new: true }`. |
| **Suppression (Delete)** | `deleteOne(query)` | Supprime un seul document correspondant à la requête. |
|  | `deleteMany(query)` | Supprime plusieurs documents correspondant à la requête. |
|  | `findByIdAndDelete(id)` | Supprime un document par son `_id`. |
| **Autres** | `countDocuments(query)` | Compte le nombre de documents correspondant à la requête. |
|  | `distinct(field)` | Retourne les valeurs uniques d'un champ spécifique. |
|  | `populate(field)` | Remplace l'ID d'une référence par le document associé. |

---

Modifions notre classe `PersonRepository` pour exploiter cette instance de `PersonModel`.

#### La méthode findAll du repository

Ce qui change :

- PLus de source de données dens le repository.
- Plus de retour sur une interface, mais sur la classe `Person` du schéma Mongoose.


````typescript
// dans person.repository.ts

async findAll(): Promise<Person[]> {
    return this.PersonModel.find().exec();
}
````

```typescript
// dans person.controller.ts

@Get()
async getAll(
  @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number
):Promise<ReturnMessageInterface>
{
  const persons = await this
                    .personRepository
                    .findAll()
  return {
    action: actions.READ,
    message: `Liste de toutes les personnes page ${page}`,
    success: true,
    data: persons
  };
}
```

#### La méthode findOneById du repository

Ce qui change :

- Le type de l'argument `id` est désormais `string`.
- Plus de retour sur une interface, mais sur la classe `Person` du schéma Mongoose.


````typescript
// dans person.repository.ts

async findOneById(
    id: string
): Promise<Person | null> 
{
    const person = await this
                    .PersonModel
                    .findById(id).exec();

    if (! person) {
      throw new NotFoundException(
        `Aucune personne avec l'id ${id}`
      );
    }

    return person;
}
````

```typescript
// dans person.controller.ts

@Get(':id')
async getOne(
  @Param('id') id: string
):Promise<ReturnMessageInterface>
{
  //try {
    const person = await this
                   .personRepository
                   .findOneById(id);
                   
    if(!person) {
      throw new NotFoundException(
        `Aucune personne avec l'id ${id}`
      );
    }
    return {
      action: actions.READ,
      message: `Une personne dont l'id est ${id}`,
      success: true,
      data: person
    };
}
```

#### La méthode delete du repository

````typescript
// dans person.repository.ts

async delete(
  id: string
): Promise<boolean> 
{
  const person = await  this
                 .PersonModel
                 .findByIdAndDelete(id)
                 .exec();

  if (! person) {
    throw new NotFoundException(`Aucune personne avec l'id ${id}`);
  }
  return true;
}
````

```typescript
// dans person.controller.ts

@Delete(':id')
async delete(
  @Param('id') id: string,
): Promise<ReturnMessageInterface>
{
  const result:boolean = await this
                         .personRepository
                         .delete(id);
  return {
    action: actions.DELETE,
    message: `Suppression d'une personne 
              dont l'id est ${id}`,
    success: result,
    data: null
  };
}
```

#### La méthode insert du repository

````typescript
// dans person.repository.ts

async insert(
  personDTO: CreatePersonDto
): Promise<Person>
{
  const newPerson = new this.PersonModel(personDTO);
  return newPerson.save();
}
````

```typescript
// dans person.controller.ts

@Post()
async insert(
  @Body() person: any
):Promise<ReturnMessageInterface>
{
  const savedPerson = await this
                      .personRepository
                      .insert(person);
  return {
    action: actions.INSERT,
    message: `Ajout d'une personne`,
    success: true,
    data: savedPerson
  };
}
```

#### Les méthodes replace et update du repository

Ici le remplacement et la mise à jour partielle seront gérées par la même méthode du repository.

Les options de `findByIdAndUpdate` sont les suivantes :

- `new` : indique s'il faut créer un document dans le cas où la recherche a été infructueuse.
- `runValidators` : indique s'il faut valider les données modifiées en fonction des contraintes définies dans le schéma. Attention, cette option est `false par défaut.



````typescript
// dans person.repository.ts

async update(
  id: number,
  personDTO: UpdatePersonDto
): Promise<Person | null>
{
  const updatedPerson = await this.PersonModel
                        .findByIdAndUpdate(
                            id, personDTO, 
                            { new: false,
                              runValidators: true }
                        );
  if (!updatedPerson) {
    throw new NotFoundException(`User with ID ${id} not found`);
  }
  
  return updatedPerson;
}
````

```typescript
// dans person.controller.ts

@Put(':id')
async replace(
  @Param('id', new ParseIntPipe()) id: number,
  @Body() person: CreatePersonDto
):Promise<ReturnMessageInterface>
{
  const replacedPerson = await this
                         .personRepository
                         .update(id, person);
  return {
    action: actions.UPDATE,
    message: `Remplacement d'une personne`,
    success: true,
    data: replacedPerson
  };
}

@Patch(':id')
async update(
  @Param('id', new ParseIntPipe()) id: number,
  @Body() person: UpdatePersonDto
): Promise<ReturnMessageInterface>
{
  const updatedPerson = await this
                        .personRepository
                        .update(id, person);
  return {
    action: actions.UPDATE,
    message: `Modification d'une personne`,
    success: true,
    data: updatedPerson
  };
}
```

### Exercice

Mettre à jour l'API Book pour persister les données avec `Mongoose`.



