# Les contrôleurs

## Créer un contrôleur

NestJS dispose d'une commande `generate` chargée d'écrire du code pour nous.

### Dans le module principal

```shell
nest generate controller <nom du contrôleur>
```

ou la version courte

```shell
nest g co <nom du contrôleur>
```

Cette commande effectue les actions suivantes :

- Créé un dossier `persons`.
- Créé un fichier `persons.controller.ts` dans le dossier `controllers`.
- Créé un fichier `persons.controller.spec.ts` dans le dossier `controllers`.
- Modifie `app.module.ts` et ajoute un import vers le nouveau contrôleur.
- Modifie `app.module.ts` et référence le nouveau contrôleur dans le tableau `controllers` du décorateur `@Module`.

> Le suffixe `Controller` est ajouté automatiquement. Si nous entrons la commande suivante `nest g co persons-controller` nous obtiendrons donc une classe `PersonControllerController`.
> 
> Notons également que par convention le nom du fichier est au pluriel et en kebab-case (tiret du 6) alors que le nom de la classe est passé au singulier et en camelCase.

Si nous ne souhaitons pas ranger les contrôleur dans un dossier `controllers`, il nous faudra ajouter l'option `--flat` à la commande.

```shell
nest g co <nom du contrôleur> --flat
```

### Dans un autre module

Pour créer un contrôleur dans un autre module, c'est très simple. Il nous suffit d'indiquer le dossier dans lequel nous souhaitons ajouter le nouveau contrôleur.

- Si le module existe, le contrôleur sera ajouté et référencé dans ce module.
- S'il n'existe pas, un nouveau module sera automatiquement créé.

Exemple, création d'un contrôleur `UserController` dans un module `UserModule`.

```shell
nest g co users/users 
```

Ajout d'un autre contrôleur à ce module.

```shell
nest g co users/users-settings 
```

### Anatomie du contrôleur

```typescript
import { Controller } from '@nestjs/common';

// déclare un contrôleur qui réagit à la route /person
@Controller('person')
export class PersonController {}
```

## Ajout de méthodes au contrôleur

Pour que le contrôleur puisse intercepter des requêtes, il lui faut des méthodes décorées par des fonctions indiquant le verbe http auquel elles doivent réagir.

### Décorateur `@Get`

```typescript
import { Controller, Get } from '@nestjs/common';

@Controller('person')
export class PersonController {
  
  @Get()
  getAll() {
    return 'Liste de toutes les personnes';
  }
}
```

Si ce n'est déjà fait, lancer le serveur avec `npm run start:dev` et tester la route. 

[`http://localhost:3000/person`](http://localhost:3000/person) {target="_blank"}


Il est possible de passer un argument à @Get pour ajouter un complément à la route.

```typescript
import { Controller, Get } from '@nestjs/common';

@Controller('person')
export class PersonController {
  
  // La route est désormais /person/all
  @Get('all')
  getAll() {
    return 'Liste de toutes les personnes';
  }
}
```

[`http://localhost:3000/person/all`](http://localhost:3000/person/all) {target="_blank"}

### Ajout d'un paramètre

Ajoutons une autre route pour obtenir une seule personne. Pour cela, nous aurons besoins de transmettre l'identifiant de cette personne.

```typescript
  @Get(':id')
  getOne(@Param('id') identifiant: number) {
    return `Une personne dont l'id est ${identifient}`;
  }
```

- Le paramètre est déclaré dans le décorateur `@Get`, les `:` indiquent qu'il s'agit d'un paramètre et non d'un simple complément de route.
- La méthode reçoit un argument, son nom est libre.
- L'argument est décoré par @Param qui permet de lier la variable au paramètre.
- Ne pas oublier d'importer `Param` si cela n'a pas été fait automatiquement.

**Test**

[`http://localhost:3000/person/1`](http://localhost:3000/person/1) {target="_blank"}

### Retour json

Pour retourner un contenu `JSON`, il suffit de renvoyer un objet littéral.

```typescript
  @Get(':id')
  getOne(@Param('id') identifiant: number) {
    return {
        id: identifiant, 
        action: 'Affichage d'une personne'
    };
  }
```

### Eviter le masquage des routes

Par défaut le paramètre capture tout type de caractères. Dans notre exemple `@Get(':id')` correspondra donc, entre autres, aux routes suivantes :

- /person/1
- /person/search

Il serait judicieux de limiter ce paramètre `id` aux seuls caractères numériques afin de ne pas masquer d'autres routes éventuelles.

La précédente version d'Express (un framework sur lequel Nestjs s'appuie) le permettait, ce n'est hélas plus le cas. Il faut désormais prendre garde à l'ordre des routes et placer celles qui utilise un paramètre aprés celles qui n'en ont pas.

<!--
Pour cela, nous pouvons passer une expression régulière dans la définition de la route, comme ceci :

```typescript
@Get(':id(\\d+)')
```

> Notons le double `\` pour échapper le caractère d'échappement.
-->
### Gestion du QueryString

Outre les paramètres, il est possible de passer des informations à une route par le biais du `QueryString`. Il s'agit de données facultatives qui sont intégrées dans la requête http après la ressource.

- Le `querystring commence par un `?` après la ressource.
- Les données sont passées sous le forme `clef=valeur`.
- Les différentes paires clefs-valeurs sont séparées par un `&`.

Quelques exemples

`http://localhost:3000/person?page=2`

`http://localhost:3000/person/search?firstName=Ada&lastName=Lovelace`

```typescript
import { Controller, Get, Param, Query } from '@nestjs/common';

@Controller('person')
export class PersonController {

  @Get()
  getAll(@Query('page')page:number = 1) {
    return `Liste de toutes les personnes page ${page}`;
  }

  @Get(':id')
  getOne(@Param('id') id: string) {
    return `Une personne dont l'id est ${id}`;
  }

  @Get('search')
  search(
    // récupération du paramètre "term" 
    // dans le querystring
    @Query('term') term: string),
    // récupération du paramètre "page" 
    // avec une valeur par défaut
    @Query('page') page:number = 1
  )
  {
    return `recherche sur ${term}`;
  }
}
```

### Décorateur `@Post`

Les données envoyées avec le verbe `POST` résident dans le corps de la requête. Il faudra donc utiliser un nouveau décorateur `@Body` pour les récupérer.

Il faudra encore une fois prendre garde aux imports.

```typescript
  @Post()
  insert(@Body() person: {id: number, name: string}) 
  {
    return `Nouvelle personne 
            dont le nom est ${person.name}
            et l'id est ${person.id}`;
  }
```

### Décorateurs `@Put` et `@Patch`
 La difference entre ces deux décorateurs est sémantique, le verbe http `PUT` est censé remplacer l'intégralité du contenu (hormis l'id), tandis que le verbe `PATCH` doit permettre une mise à jour partielle.

Ces deux méthodes ressemblent beaucoup à l'insertion, la différence ici réside dans le paramètre `id` qui définit la personne à modifier.

```typescript
  @Put(':id')
  replace(
    @Param('id') id: number,
    @Body() person: {name: string}
  )
  {
    return `Modification d'une personne 
            le nouveau nom est ${person.name}
            et l'id est ${id}`;
  }
  
  @Patch(':id')
  update(
    @Param('id') id: number,
    @Body() person: {name: string}
  )
  {
    return `Modification d'une personne 
            le nouveau nom est ${person.name}
            et l'id est ${id}`;
  }

```

### Décorateur `@Delete`

Enfin le décorateur `@Delete` est utilisé pour la suppression.

```typescript
  @Delete(':id')
  delete(@Param('id') id: number)
  {
    return `Suppression d'une personne 
            dont l'id est ${id}`;
  }
```

### Gestion des en-têtes http

Pour lire les en-têtes http, nous utiliserons le décorateur `@Headers`.

```typescript
  @Get('with-token')
  withToken(
      // récupération d'un en-tête spécifique
      @Headers('x-token') token:string
  ): string
  {
    return `token = ${token}`;
  }

  @Get('with-all-headers')
  withAllHeaders(
    // récupération de tous les en-têtes
    // Record est un objet TypeScript qui se comporte
    // comme un Map Java (tableau associatif)
    @Headers() headers: Record<string, string>
  ): string
  {
    return headers.toString();
  }
```

#### Quelques en-têtes fréquents

| En-tête                      | Description                                                                          | Exemple                                                   |
|------------------------------|--------------------------------------------------------------------------------------|-----------------------------------------------------------|
| Authorization                | Jeton d'authentification                                                             | Authorization: Bearer eyJhbG...                           |
| X-Token                      | Jeton d'authentification (alternative)                                               | X-Token: my-secret-token                                  |
| X-API-Key                    | Clé utilisée pour l'accès à certaines API	                                           | X-API-Key: 123456                                         |
| Access-Control-Allow-Origin  | Autorise des domaines spécifiques à accéder à l'API                                  | Access-Control-Allow-Origin: *                            |
| Access-Control-Allow-Methods | Spécifie les méthodes HTTP autorisées                                                | Access-Control-Allow-Methods: GET, POST                   |
| Access-Control-Allow-Headers | Spécifie les en-têtes HTTP autorisés                                                 | Access-Control-Allow-Headers: Authorization, Content-Type |
| Content-Type                 | Indique le format des données envoyées dans la requête                               | Content-Type: application/json                            |
| Accept                       | Spécifie le format attendu dans la réponse                                           | Accept: application/json                                  |
| X-Frame-Options              | Empêche l’intégration dans une iframe (protection contre les attaques clickjacking). | X-Frame-Options: DENY                                     |

## Tester une route

Pour les routes utilisant le verbe http GET, un navigateur fait l'affaire. Pour les autres types de routes il faut utiliser un outil pour envoyer des requêtes.

#### CURL

CURL est un outil en ligne de commande qui permet d'envoyer des requêtes depuis un terminal.

##### Envoi d'une requête GET

```shell
curl -X GET http://localhost:3000/person
```

##### Enregistrement du résultat dans un fichier

```shell
curl -o response.json -X GET http://localhost:3000/person
```

ou

```shell
curl -X GET http://localhost:3000/person > response.json
```

##### Envoi d'une requête avec transmission de données

```shell
curl -X POST http://localhost:3000/person \
     -H "Content-Type: application/json" \
     -d '{"id": 1, "name": "Saoirse"}' 
```

- `-H`, ajoute un en-tête http.
- `-d`, définit les données (data) transmises dans le corps de la requête.

La transmission de données est utilisée avec les verbes `POST`, `PUT`et `PATCH`.

##### Envoi d'une requête avec authentification

```shell 
curl -X GET http://localhost:3000/person \
     -H "Authorization: Bearer <TOKEN>" \
     -H "Accept: application/json"
```

#### Postman

Pour une expérience plus graphique, nous pouvons utiliser `Postman` téléchargeable à l'adresse suivante :

[Téléchager Postma](https://www.postman.com/downloads/)

Il existe également une version en ligne sans installation

![CleanShot 2025-02-15 at 16.14.02@2x.png](CleanShot 2025-02-15 at 16.14.02@2x.png)

#### Plugin pour Visual Studio Code

L'outil le plus populaire est l'extension `Thunder Client`.

![CleanShot 2025-02-15 at 16.14.52@2x.png](CleanShot 2025-02-15 at 16.14.52@2x.png)

![CleanShot 2025-02-15 at 16.16.40@2x.png](CleanShot 2025-02-15 at 16.16.40@2x.png)

#### WebStorm HTTP Client

Menu : `Tools > HTTP Client`


![CleanShot 2025-02-15 at 16.18.49@2x.png](CleanShot 2025-02-15 at 16.18.49@2x.png)


### Test des routes avec WebStorm

**Enregister dans `http-client/test-person.http`**.

```http request
### Test de la récupération de toutes les personnes

GET http://localhost:3000/person
Accept: application/json
Content-Type: application/json


### Test de la récupération d'une personne

GET http://localhost:3000/person/1
Accept: application/json


### Test de la récupération d'une personne inexistante

GET http://localhost:3000/person/10000
Accept: application/json


### Test de la création d'une personne

POST http://localhost:3000/person/
Accept: application/json
Content-Type: application/json

{
  "firstName": "Melanie",
  "lastName": "Rawn",
  "age": 50,
  "email": "melanie.rawn@gmail.com"
}


### Test du remplacement d'une personne

PUT http://localhost:3000/person/2
Accept: application/json
Content-Type: application/json

{
"firstName": "Annie",
"lastName": "Leibovitz",
"age": 54,
"email": "a.leibovitz@gmail.com"
}


### Test du remplacement d'une personne inexistante

PUT http://localhost:3000/person/10000
Accept: application/json
Content-Type: application/json

{
  "firstName": "Annie",
  "lastName": "Leibovitz",
  "age": 54,
  "email": "a.leibovitz@gmail.com"
}


### Test de la modification d'une personne

PATCH http://localhost:3000/person/2
Accept: application/json
Content-Type: application/json

{
  "firstName": "Tal"
}


### Test de la modification d'une personne inexistante

PATCH http://localhost:3000/person/10000
Accept: application/json
Content-Type: application/json

{
  "firstName": "Tal"
}


### Test de la suppression d'une personne

DELETE http://localhost:3000/person/2
Accept: application/json


### Test de la suppression d'une personne inexistante

DELETE http://localhost:3000/person/10000
Accept: application/json

```

## Exercice

Créer un contrôleur `BookController` dans un module `BookModule`.


Le retour des routes sera un objet contenant le message et les éventuelles données envoyées.

```javascript
{
    message: 'le message'
    data: {}
}
```

#### Créer les routes suivantes :

| méthode | route        | message                                                       |
|---------|--------------|---------------------------------------------------------------|
| GET     | /book        | Liste des livres                                              |
| GET     | /book/:id    | Affichage du livre id                                         |
| GET     | /book/search | Recherche des livre, <br/>afficher les données du querystring |
| POST    | /book        | Nouveau livre (afficher les données postées)                  |
| PUT     | /book/:id    | Remplacement d'un livre (afficher les données postées)        |
| PATCH   | /book/:id    | Modification d'un livre (afficher les données postées)        |
| DELETE  | /book/:id    | Suppression d'un livre (afficher l'id)                        |

**Tester avec un client tel que Postman, Thunder (Vs Code) ou le client http de WebStorm.**
