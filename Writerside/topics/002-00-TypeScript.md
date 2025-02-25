# TypeScript

TypeScript est un superset de JavaScript développé par Microsoft. Cela signifie qu'il ajoute des fonctionnalités supplémentaires à JavaScript tout en restant compatible avec lui. Son principal objectif est d'améliorer la sécurité du code et la productivité des développeurs grâce à un système de types statiques.

Avant le déploiement, les fichiers `TypeScript` (.ts) seront transpilés (combinaison de translation et compilation) pour générer des fichiers `Javascript` que les navigateurs savent interpréter. 

## Les bases de TypeScript

### Variables scalaires

```typescript
// Le type est déclaré 
// après le nom de la variable
// et avant l'affectation
let message: string = "Hello, TypeScript!";
let age: number = 30;
let isActive: boolean = true;
```

### Variables composites

#### Tableaux

```typescript
// Tableau de chaînes
let names: string[] = [
    "Alice", "Bob", "Charlie"
]; 
// Syntaxe alternative
let names: Array<string> = [
    "Alice", "Bob", "Charlie"
]; 
```

#### Objets littéraux

```typescript
let user: { name: string; age: number } = { name: "Alix", age: 25 };
```

#### Tableaux d'objets

```typescript
let users: Array<{ name: string; age: number }> = [
    { name: "Alix", age: 25 },
    { name: "Sidonie", age: 24 },
    { name: "Aoife", age: 34 }
];
```

### Interfaces
Les interfaces permettent de définir des structures d’objets et sont très utilisées pour les API et la programmation orientée objet. Avec TypeScript elles servent également à simplifier l'utilisation d'objets littéraux.

```
interface UserInterface {
   name: string; 
   age: number;
}

let users: UserInteface[] = [
    { name: "Alix", age: 25 },
    { name: "Sidonie", age: 24 },
    { name: "Aoife", age: 34 }
];

// ou bien
let users: Array<UserInteface> = [
    { name: "Alix", age: 25 },
    { name: "Sidonie", age: 24 },
    { name: "Aoife", age: 34 }
];
```

### Classes

Il est bien entendu possible de typer sur une classe.

```typescript
let request: Request = new Request();
```

### Fonctions

Il est non seulement possible de typer les arguments d'une fonction, mais aussi sa valeur de retour.

```typescript
fonction greet(name: string): string{
    return `Hello ${name}`;
}
```

> Si une fonction ne retourne rien, le type de retour sera `void`.

```typescript
    function sayHello():void{
        console.log('Hello');
    }
```

### Types génériques

```typescript
function identity<T>(value: T): T {
  return value;
}

console.log(identity<string>("Hello")); // "Hello"
console.log(identity<number>(42)); // 42

```

### Enumérations

En TypeScript, un enum (abréviation de "enumeration") est une manière de définir un groupe de constantes nommées. 

Les enum sont utilisés pour représenter un ensemble de valeurs possibles qui sont fixes et permettent de rendre le code plus lisible et compréhensible. 

Cela permet en quelque sorte d'attribuer un namespace à un groupe de constantes.

```typescript
const enum Direction {
  Up = "UP",
  Down = "DOWN",
  Left = "LEFT",
  Right = "RIGHT",
}

let move: Direction = Direction.Up;
console.log(move); // "UP"

```

### Union type

Permet de typer sur plusieurs types.

```typescript
function double(value: string | number): string | number {
  if (typeof value === "number") {
    return value * 2;
  } else {
    return value.repeat(2);
  }
}

console.log(double(5));     // 10
console.log(double("Hi"));  // "HiHi"
```

> Il existe également un type `any` qui remplace tous les types, mais il est à utiliser avec parcimonie.

#### Variable ou propriété nullable

```typescript
let userName: string = null; // ❌ Erreur
let age: number = undefined; // ❌ Erreur

let userName: string | null = null; // ✅ OK
let age: number | undefined = undefined; // ✅ OK
```

#### Null coalesce

L’opérateur `??` renvoie la valeur de droite si la valeur de gauche est `null` ou `undefined`.

```typescript
let input: string | null = null;
let output = input ?? "Default Value"; // ✅ "Default Value"
console.log(output);
```

## Les classes

TypeScript apporte quelques améliorations par rapport aux classes JavaScript.

### Les opérateurs de portée

Comme dans bien d'autres langages de programmation orientés objet, la portée des propriétés ou des méthodes est gérée par les mots-clefs `public`, `protected` ou `private`. 

```typescript

class User {
    private name: string;
    private age: number;
    
    // public étant la portée par défaut, 
    // il est possible d'omettre l'opérateur
    public constructor(name: string, age: number): void {
        this.name = name;
        this.age = age;
    }
}

```

### La promotion des arguments du constructeur

La promotion des arguments du constructeur en TypeScript permet de déclarer et d'initialiser automatiquement les propriétés d'une classe directement dans le constructeur.
Cela évite d’écrire du code répétitif et améliore la lisibilité.

```typescript
class Person {
  constructor(
    public name: string, 
    public age: number
  ) {}
}
```

### propriété en lecture seule

l'opérateur `readonly` définit qu'une propriété est en lecture seule.

```typescript
class Product {
  constructor(
    public readonly id: number, 
    public name: string
  ) {}
}

const product = new Product(1, "Laptop");
console.log(product.id); // ok 1
product.id = 2; // Erreur : `id` est `readonly`
```

### Propriété optionnelle

Une propriété optionnelle peut être `undefined`, mais pas `null`. Pour la déclarer comme tel, il faut placer un `?`aprés le nom de la variable.

```typescript
class Person {
  constructor(
    public name: string, 
    public age?: number
  ) {}
}
```

#### Chaînage optionnel

```typescript
const user = {
  name: "Alice",
  address: null,
};

//undefined (évite une erreur)
console.log(user.address?.street); 
```

### Propriété initialisée plus tard

Parfois, une propriété ne peut pas être initialisée immédiatement.
L’opérateur `!` (Non-null Assertion Operator) indique à TypeScript que la valeur sera définie.

```typescript
class Config {
  // `!` : TypeScript suppose qu'elle sera définie plus tard
  databaseUrl!: string; 

  setDatabase(url: string) {
    this.databaseUrl = url;
  }

  getDatabase(): string {
    return this.databaseUrl;
  }
}

const config = new Config();
config.setDatabase("https://mydatabase.com");
console.log(config.getDatabase()); // ✅ "https://mydatabase.com"
```

## Comment utiliser TypeScript

> Cette procédure est inutile avec `Nestjs` ou `Angular` car les fichiers sont automatiquement transpilés par le framework.

### Transpiler un seul fichier
<procedure>
<step>
Installation

```shell
npm install -g typescript
```
</step>
<step>
Transpiler un ficher TypeScript en Javascript

```shell
tsc fichier.ts
```
</step>

<step>
Exécuter avec Nodejs (après compilation)

```shell
node fichier.js
```
</step>
</procedure>

### Transpiler plusieurs fichiers

<procedure>
<step>
Créer un fichier de configuration

```shell
tsc --init
```
</step>

<step>
Créer un fichier de configuration

```shell
tsc --init
```
</step>

<step>
Modifier le fichier tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES6",              
    "module": "CommonJS",          
    "outDir": "./dist",            
    "rootDir": "./src",            
    "strict": true,                
    "noImplicitAny": true,         
    "esModuleInterop": true        
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```
</step>
<step>
Transpiler

```shell
tsc
```

Ou bien activer la transpilation automatique à chaque changement dans le code source

```shell
tsc --watch
```

</step>
</procedure>

#### Explication des options de tsconfig

| Option                  | Explication |
|-------------------------|------------|
| `"target": "ES6"`       | Compile TypeScript en JavaScript ES6. |
| `"module": "CommonJS"`  | Utilisé pour Node.js. |
| `"outDir": "./dist"`    | Met les fichiers `.js` compilés dans `dist/`. |
| `"rootDir": "./src"`    | Indique où sont les fichiers `.ts`. |
| `"strict": true`        | Active toutes les vérifications strictes (meilleure sécurité). |
| `"noImplicitAny": true` | Interdit `any` implicite (évite les erreurs de typage). |
| `"esModuleInterop": true` | Permet d'importer des modules ES6 plus facilement. |

> `include` détermine quels fichiers doivent être transpilés au sein de `rootDir`. Dans notre exemple, il est possible d'omettre cette inclusion puisqu'elle porte sur l'ensemble des fichiers de `rootDir`.

### Exécuter des fichiers `TypeScript` directement avec `Nodejs`

```shell
npm install -g ts-node
```

```shell
ts-node fichier.ts
```


## Avantages de TypeScript

- **Typage statique** : Contrairement à JavaScript (typé dynamiquement), TypeScript permet de définir des types pour les variables, fonctions et objets.
- **Meilleure maintenabilité** : Les erreurs sont détectées avant l'exécution, évitant ainsi les bugs en production.
- **Autocomplétion et documentation améliorée** : Avec un IDE comme VS Code, TypeScript propose de meilleures suggestions et une documentation automatique.
- **Compatibilité avec JavaScript** : Tout code JavaScript est valide en TypeScript (mais l'inverse n’est pas toujours vrai).
- **Support des dernières fonctionnalités ECMAScript** : TypeScript permet d'utiliser des fonctionnalités modernes avant qu'elles ne soient prises en charge par tous les navigateurs.
