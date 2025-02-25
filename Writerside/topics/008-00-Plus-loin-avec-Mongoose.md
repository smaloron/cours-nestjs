# Plus loin avec Mongoose

## Héritage plutôt qu'hydratation

Il existe une alternative à `hydrateDocument` qui permet de fusionner la classe entité et le document. Il suffit que cette classe hérite de `Document`.

```typescript

// person/person.schema.ts

import { Schema, SchemaFactory } from '@nestjs/mongoose';
import { Prop } from '@nestjs/mongoose';
//import { HydratedDocument } from 'mongoose';
import { Document } from 'mongoose';

// Définition des champs 
// et des contraintes Schéma
@Schema()
export class Person extends Document {
  @Prop({ required: true })
  firstName: string;

  @Prop({ required: true })
  lastName: string;
}

// Ce n'est plus nécéssaire, Person est désormais un Document
// export type PersonDocument = HydratedDocument<Person>;

// Création d'un schéma Mongoose à partir de la définition
export const PersonSchema = SchemaFactory.createForClass(Person);
````

Lors de l'injection, nous ferons donc référence à la classe `Person`.

```typescript
constructor(
    @InjectModel('Person') private PersonModel:Model<Person>
) {}
```

## Les types de champs

| Type Mongoose  | Type TypeScript      | Description                        | Exemple |
|---------------|--------------------|--------------------------------|---------|
| `String`     | `string`           | Chaîne de caractères          | `@Prop({ type: String }) name: string;` |
| `Number`     | `number`           | Nombre (entier ou décimal)    | `@Prop({ type: Number }) age: number;` |
| `Boolean`    | `boolean`          | Valeur booléenne (`true/false`) | `@Prop({ type: Boolean }) isActive: boolean;` |
| `Date`       | `Date`             | Date et heure                 | `@Prop({ type: Date, default: Date.now }) createdAt: Date;` |
| `Array`      | `Array<any>`       | Tableau de valeurs            | `@Prop({ type: [String] }) tags: string[];` |
| `ObjectId`   | `Types.ObjectId`   | Référence à un autre document  | `@Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'User' }) user: User;` |
| `Mixed`      | `any`              | Tout type de données          | `@Prop({ type: mongoose.Schema.Types.Mixed }) metadata: any;` |
| `Buffer`     | `Buffer`           | Données binaires              | `@Prop({ type: Buffer }) file: Buffer;` |
| `Map`        | `Map<string, any>` | Objet clé-valeur              | `@Prop({ type: Map, of: String }) settings: Map<string, string>;` |

#### Exemple

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

export type UserDocument = HydratedDocument<User>;

@Schema()
export class User {
  @Prop({ type: String, required: true })
  name: string;

  @Prop({ type: Number, min: 18, max: 100 })
  age: number;

  @Prop({ type: Boolean, default: true })
  isActive: boolean;

  @Prop({ type: Date, default: Date.now })
  createdAt: Date;

  @Prop({ type: [String] })
  roles: string[];

  @Prop({ type: mongoose.Schema.Types.ObjectId, ref: 'Profile' })
  profile: Types.ObjectId;

  @Prop({ type: mongoose.Schema.Types.Mixed })
  extraData: any;

  @Prop({ type: Buffer })
  avatar: Buffer;

  @Prop({ type: Map, of: String })
  settings: Map<string, string>;
}

export const UserSchema = SchemaFactory.createForClass(User);

```

## Imbrication de documents
Il est également possible d'utiliser un schéma en tant que type de champ dans un autre schéma. Cela permet une imbrication de documents.

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type UserDocument = HydratedDocument<User>;

@Schema()
export class Address {
  @Prop({ type: String })
  street: string;

  @Prop({ type: String })
  city: string;

  @Prop({ type: String })
  country: string;
}
// Création du schéma pour l'adresse
const AddressSchema = SchemaFactory.createForClass(Address);

@Schema()
export class User {
  @Prop({ required: true })
  name: string;
  
  // Imbrication du schéma pour l'adresse
  @Prop({ type: AddressSchema }) 
  address: Address;
}

export const UserSchema = SchemaFactory.createForClass(User);

```

Il est également possible de définir un tableau de sous documents

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';
import { Address, AddressSchema } from './address.schema';

export type UserDocument = HydratedDocument<User>;

@Schema()
export class User {
  @Prop({ required: true })
  name: string;

  // Tableau de sous-documents
  @Prop({ type: [AddressSchema], default: [] }) 
  addresses: Address[];
}

export const UserSchema = SchemaFactory.createForClass(User);

```
## Les références

Lorsqu'un schéma référence un autre document par le biais d'un `ObjectId`, il faut utiliser une action d'agrégation `$lookup` pour récupérer les données liées. Fort heureusement `Mongoose` propose une fonction `populate()` pour simplifier cette opération.

### Exemple {id="exemple_1"}

Nous avons ici deux schémas, `Address` et `Person`. 

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema()
export class Address extends Document {
  @Prop({ required: true })
  street: string;

  @Prop({ required: true })
  city: string;

  @Prop({ required: true })
  country: string;
}

export const AddressSchema = SchemaFactory.createForClass(Address);

```

```typescript
import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Schema as MongooseSchema, Types } from 'mongoose';
import { Address } from './address.schema';

@Schema()
export class Person extends Document {
  @Prop({ required: true })
  name: string;

  @Prop({ type: MongooseSchema.Types.ObjectId, ref: 'Address' })
  address: Types.ObjectId;
}

export const PersonSchema = SchemaFactory.createForClass(Person);

```

Voici la requête pour obtenir les données du document lié.

```typescript
this.personModel.find().populate('address').exec();
```

Et voici l'intégration dans un service

```typescript
import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Person } from './schemas/person.schema';
import { Address } from './schemas/address.schema';

@Injectable()
export class PersonService {
  constructor(
    @InjectModel(Person.name) private personModel: Model<Person>,
    @InjectModel(Address.name) private addressModel: Model<Address>,
  ) {}

  async createPerson(name: string, addressId: string): Promise<Person> {
    const person = new this.personModel({ name, address: addressId });
    return person.save();
  }

  async getAllPersons(): Promise<Person[]> {
    return this.personModel.find().populate('address').exec();
  }
}
```
