# About

This documentation presents the ways to configure [comma](https://github.com/ximenesyuri/comma): a universal project manager.

# Ways

There are essentially two ways to configure `comma`:
1. using environment variables
2. using `yaml` files.

> If both are set, `yaml` files will overwrite the env values.

# Kinds

There are also two kinds of configuration:
1. object configuration
2. user settings

Object configurations applies to `comma` objects and need to be shared between the `comma` users, while user settings are specific to a single user.

> Environment variables can control only user settings. Object configuration are set only via config files.

# Structure

`comma` uses envs do determine its directory structure. These are the *structural envs*.
```
env                description                    default value
---------------------------------------------------------------------------------------
COMMA              installation path              $XDG_CONFIG_HOME || $HOME/.config
COMMA_DOC          dir w/ docs                    $COMMA/doc
COMMA_SH_CORE      dir w/ core scripts            $COMMA/sh/core
COMMA_SH_OBJS      dir w/ objects scripts         $COMMA/sh/objs
COMMA_SRC_YML      dir w/ inner 'yml' files       $COMMA/src/yml
COMMA_SRC_TPL      dir w/ template files          $COMMA/src/tpl
COMMA_SRC_THEMES   dir w/ pre-defined themes      $COMMA/src/themes
```

# User

There are two files involved in user configuration:
1. `conf.yml`: with local settings
2. `theme files`: with custom themes definition files

Its locations are set by the following envs.

```
env                 description                    default value
-------------------------------------------------------------------------------
COMMA_CONF          path to yml conf file          $COMMA/yml/conf.yml
COMMA_THEMES        dir w/ custom themes           $COMMA/yml/themes
```

## Conf

The `conf.yml` file uses the following schema:

```yaml
conf:
    general:
        <key>: <value>
    commands:
        <key>: <value>
    custom:
        <key>: <value>
        
        
```

The available keys and the expected pattern of the values are:

``` 
key                  description                        value         default
----------------------------------------------------------------------------------
general.editor       editor to open files               string         $EDITOR
general.browser      browser to open urls               string         $BROWSER
general.pager        pager to view files                string         $PAGER
commands.main        main command to default object     string         cd
commands.dot         dot command                        string         cd
custom:              custom commands                    array          null
```

The `.conf.general`  and `.conf.commands` can be overwrite by envs, as follows:

```
key                  env
---------------------------------------------
general.editor       COMMA_GENERAL_EDITOR
general.browser      COMMA_GENERAL_BROWSER
general.pager        COMMA_GENERAL_PAGER
commands.main        COMMA_COMMANDS_MAIN
commands.dot         COMMA_COMMANDS_DOT
```

## Themes

The `theme.yml` files uses the following schema:

```yaml
theme:
    metadata:
        <key>: <entry>
    spec:
        colors:
            <key>: <entry>
        structure:
            <key>: <entry>
```

# Objects

Recall that `comma` manage the following objects:
1. projects 
2. providers
3. pipelines
4. hooks
5. teams
6. resources

Each object has its owns `yml` configuration file:
1. `projects.yml`
2. `providers.yml`
3. `pipelines.yml`
4. `hooks.yml`
5. `teams.yml`
6. `resources.yml`

The default location of object configuration is the subdir `$COMMA/yml/obj`. You can overwrite the above locations by setting the envs `COMMA_YML` and `COMMA_OBJ`.

> If `COMMA_YML` is set but `COMMA_OBJ` is not, then `COMMA_OBJ` is supposed to be `${COMMA_YML}/obj`.

## Schema

Each `yaml` file has its own `yaml` schema. However, all of them share the same `k8s`-like basic structure:

```yaml
objects_name: ............... projects, providers, pipelines or hooks
    some_object: ............ some object label
        metadata: ........... with catalog info
            <key>: <entry>
        spec: ............... with specific entries, depending on the type
            <key>: <entry>
```

For example, in the case of a project:

```yaml
projects:
    my_project:
        metadata:
            ...
        spec:
            ...
```

## User

Among the object configuration files above, there are the user configuration files.

# Project Configuration

`comma` can be configured into four layers:

```
layer              scope            file
-------------------------------------------------
envs               global           .bashrc
globals conf       global           globals.yml
projects conf      project          projects.yml
repository conf    project          .comma.yml


