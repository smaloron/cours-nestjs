# Organisation du code

## Deux approches

1. Approche modulaire (Un dossier par module)
2. Approche par type (Séparer DTO, services, interfaces, etc.)

## L'approche modulaire

Dans cette approche, chaque module possède son propre dossier contenant tous les fichiers dont le module a besoin pour travailler (contrôleurs, services...).

Les fichiers qui sont utilisés dans plusieurs modules sont regroupés dans un dossier `common`.

NestJS préconise d'utiliser cette approche, héritant en cela d'Angular dont il est très inspiré.

```
src/
│── app.module.ts
│── main.ts
│
├── users/
│   ├── dto/
│   │   ├── create-user.dto.ts
│   │   ├── update-user.dto.ts
│   │
│   ├── entities/
│   │   ├── user.entity.ts
│   │
│   ├── interfaces/
│   │   ├── user.interface.ts
│   │
│   ├── users.controller.ts
│   ├── users.service.ts
│   ├── users.module.ts
│
├── auth/
│   ├── dto/
│   │   ├── login.dto.ts
│   │   ├── register.dto.ts
│   │
│   ├── entities/
│   │   ├── user-token.entity.ts
│   │
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── auth.module.ts
│
├── common/
│   ├── decorators/
│   │   ├── roles.decorator.ts
│   │
│   ├── filters/
│   │   ├── http-exception.filter.ts
│   │
│   ├── interceptors/
│   │   ├── logging.interceptor.ts
│   │
│   ├── guards/
│   │   ├── auth.guard.ts
│   │
│   ├── pipes/
│   │   ├── validation.pipe.ts
│
├── database/
│   ├── database.module.ts
│   ├── database.service.ts
│
├── config/
│   ├── config.module.ts
│   ├── config.service.ts
│   ├── app.config.ts
│

```

### Avantage de cette approche

- Facile à comprendre : Chaque module a son propre dossier, donc il est facile de naviguer dans le projet.
- Scalabilité : Permet d’ajouter facilement de nouveaux modules sans affecter les autres.
- Encapsulation : Les modules sont indépendants et peuvent être réutilisés dans d'autres projets.

## L'approche par type

Dans cette approche, les fichiers sont classés par type plutôt que par module. Bien des Frameworks préconisent cette approche (Symfony; Express...). 

```
src/
│── app.module.ts
│── main.ts
│
├── controllers/
│   ├── users.controller.ts
│   ├── auth.controller.ts
│
├── services/
│   ├── users.service.ts
│   ├── auth.service.ts
│
├── modules/
│   ├── users.module.ts
│   ├── auth.module.ts
│
├── dto/
│   ├── create-user.dto.ts
│   ├── update-user.dto.ts
│   ├── login.dto.ts
│   ├── register.dto.ts
│
├── entities/
│   ├── user.entity.ts
│   ├── user-token.entity.ts
│
├── interfaces/
│   ├── user.interface.ts
│
├── middlewares/
│   ├── logging.middleware.ts
│
├── guards/
│   ├── auth.guard.ts
│
├── pipes/
│   ├── validation.pipe.ts
│
├── interceptors/
│   ├── logging.interceptor.ts

```

### Avantage de cette approche {id="avantage-de-cette-approche_1"}

- Regroupement clair des types : Tous les services, DTOs et contrôleurs sont dans des dossiers spécifiques.
- Facile pour les petits projets : Pour un projet simple, cette organisation peut être plus rapide à mettre en place.

## Réorganisation de notre code

<procedure>
<step>
Commençons par créer un module person.

```shell
nest generate module person
```
</step>

<step>
Déplaçons ensuite les fichiers suivants dans le dossier `person`.

- person.controller.ts
- person.controller.spec.ts

</step>

<step>
Dans person.module.ts, nous ajoutons PersonController au tableau des controllers.

</step>

<step>
Modifions app.module.ts :

- Ajout du module person aux imports
- Suppression de PersonController dans le tableau controllers

![CleanShot 2025-02-16 at 07.34.27@2x.png](CleanShot 2025-02-16 at 07.34.27@2x.png)
</step>
</procedure>

