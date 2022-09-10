# Description
Manage map entites using EntityLump. Create a config file in configs/mapentities with the name of the map to manage map entities.

# Dependencies
Sourcemod 1.12 (6922 version) or a higher one.

# Commands
```
sm_dump_entitylump <file> - Dumps all map entities data in a file.
```

# Examples
## Add entities
- Both key and value are required when you add a keyvalue.
- Use output: 1 if the keyvalue is an output.

```
"Add Entities"
{
	"entity"
	{
		"keyvalue"
		{
			"key"		"classname"
			"value"		"weapon_ak47"
		}
		
		"keyvalue"
		{
			"key"		"origin"
			"value"		"0 0 0"
		}
		
		"keyvalue"
		{
			"key"		"spawnflags"
			"value"		"1"
		}
		
		"keyvalue"
		{
			"key"		"OnPlayerUse"
			"value"		"!caller:SetAmmoAmount:1:0:-1"
			"output"	"1"
		}
	}
	
	"entity"
	{
		"keyvalue"
		{
			"key"		"classname"
			"value"		"prop_dynamic"
		}
		
		"keyvalue"
		{
			"key"		"origin"
			"value"		"256 32 16.500"
		}
		
		"keyvalue"
		{
			"key"		"model"
			"value"		"models/props_junk/garbage_metalcan002a.mdl"
		}
	}
}
```

## Delete entities
- Both key and value are required when you search for a keyvalue.
- Use output: 1 if the keyvalue is an output.

```
"Delete Entities"
{
	"entity"
	{
		"match"
		{
			"keyvalue"
			{
				"key"		"hammerid"
				"value"		"44512" // delete the entity with this hammerid
			}
		}
	}
	
	"entity"
	{
		"match"
		{
			"keyvalue"
			{
				"key"		"classname"
				"value"		"trigger_hurt" // delete all trigger_hurt entities
			}
		}
	}
	
	"entity"
	{
		"match"
		{
			"keyvalue"
			{
				"key"		"classname"
				"value"		"func_button"
			}
			
			"keyvalue"
			{
				"key"		"OnPressed"
				"value"		"trap1:Close::5:-1" // delete all func_button entities with this output
				"output"	"1"
			}
		}
	}
}
```
