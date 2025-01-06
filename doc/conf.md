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

# Files

Let us focus first in described the files involved in the configuration of `comma`.

## Dir

By default, `comma` reads for configuration in files in the directory `$COMMA/yml`, where `$COMMA` is the installation path of comma. Actually, it looks to the following subdirectories:
1. `$COMMA/yml/obj`: for object configuration
2. `$COMMA/yml/usr`: for user settings

> You can use the envs `COMMA_CONF`, `COMMA_CONF_OBJ` and `COMMA_CONF_USR` to set different config directories for `comma`. 
> 1. if `COMMA_CONF` is set but the others are not, it will automatically set 
>   1. `COMMA_CONF_OBJ=$COMMA_CONF/obj`
>   2. `COMMA_CONF_USR=$COMMA_CONF/usr`
> 2. if `COMMA_CONF` is not set, but the others are, them `comma` will look to the directories defined by them
> 3. if all the envs are set, the `COMMA_CONF` will be ignored

## Objects

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

> You can overwrite the default location `comma/yml` by setting the env `COMMA_CONF` with your custom directory. In this case, `comma` will look at:
> 1. `$COMMA_CONF/projects.yml`
> 2. `$COMMA_CONF/providers.yml`
> 3. and so on

## Schema

Each `yaml` file has its own `yaml` schema. However, all of them share the same `k8s`-like basic structure:

```yaml
objects_name: ............... projects, providers, pipelines or hooks
    some_object: ............ some object label
        metadata: ........... with catalog info
            ...
        spec: ............... with specific entries, depending on the type
            ...
```

## Globals

Among the object configuration files above, there are the `globals.yml` file. The cond

# Project Configuration

`comma` can be configured into four layers:

```
layer              scope            file
-------------------------------------------------
envs               global           .bashrc
globals conf       global           globals.yml
projects conf      project          projects.yml
repository conf    project          .comma.yml


