#pragma semicolon 1
#pragma dynamic 131072
#pragma newdecls required

#include <sourcemod>
#include <clearhandle>

enum KeyType
{
	KeyType_None,
	KeyType_Output
}

enum ValueType
{
	ValueType_None,
	ValueType_AddFlags,
	ValueType_Max,
	ValueType_Min,
	ValueType_SubstractFlags
}

enum struct KeyValueInfo
{
	char key[256];
	char value[512];
}

char g_OutputActionSeparator[256];

ArrayList g_List_KeyValues;
ArrayList g_List_LumpEntriesPosition;

StringMap g_Map_ValueTypes;

public Plugin myinfo =
{
	name = "Map Entities",
	author = "Ilusion",
	description = "Manage map entites.",
	version = "1.0",
	url = "https://github.com/Ilusion9/"
};

public void OnPluginStart()
{
	g_List_LumpEntriesPosition = new ArrayList();
	g_List_KeyValues = new ArrayList(sizeof(KeyValueInfo));
	
	g_Map_ValueTypes = new StringMap();
	g_Map_ValueTypes.SetValue("add_flags", ValueType_AddFlags);
	g_Map_ValueTypes.SetValue("max", ValueType_Min);
	g_Map_ValueTypes.SetValue("min", ValueType_Max);
	g_Map_ValueTypes.SetValue("substract_flags", ValueType_SubstractFlags);
	
	EngineVersion engineVersion = GetEngineVersion();
	if (engineVersion == Engine_CSS)
	{
		strcopy(g_OutputActionSeparator, sizeof(g_OutputActionSeparator), ",");
	}
	else
	{
		strcopy(g_OutputActionSeparator, sizeof(g_OutputActionSeparator), "\e");
	}
	
	RegAdminCmd("sm_dump_entitylump", Command_DumpEntityLump, ADMFLAG_RCON, "sm_dump_entitylump <file>");
}

public void OnMapInit()
{
	ClearArray_Ex(g_List_KeyValues);
	ClearArray_Ex(g_List_LumpEntriesPosition);
	
	char path[PLATFORM_MAX_PATH];
	KeyValues kv = new KeyValues("Map Entities");
	
	GetCurrentMap(path, sizeof(path));
	BuildPath(Path_SM, path, sizeof(path), "configs/mapentities/%s.cfg", path);
	
	if (kv.ImportFromFile(path))
	{
		if (kv.JumpToKey("Delete Entities"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					if (!kv.JumpToKey("match"))
					{
						continue;
					}
					
					if (kv.GotoFirstSubKey(false))
					{
						do
						{
							KeyValueInfo keyValueInfo;
							kv.GetString("key", keyValueInfo.key, sizeof(KeyValueInfo::key));
							kv.GetString("value", keyValueInfo.value, sizeof(KeyValueInfo::value));
							
							if (kv.GetNum("output"))
							{
								PrepareOutputAction(keyValueInfo.value, sizeof(KeyValueInfo::value));
							}
							
							g_List_KeyValues.PushArray(keyValueInfo);
						}
						while (kv.GotoNextKey(false));
						kv.GoBack();
					}
					
					kv.GoBack();
					
					int pos = -1;							
					while ((pos = FindLumpEntryByKeyValues(pos, g_List_KeyValues)) != -1)
					{
						EntityLump.Erase(pos);
						pos--;
					}
					
					ClearArray_Ex(g_List_KeyValues);
				}
				while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
		
		if (kv.JumpToKey("Modify Entities"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					if (!kv.JumpToKey("match"))
					{
						continue;
					}
					
					if (kv.GotoFirstSubKey(false))
					{
						do
						{
							KeyValueInfo keyValueInfo;
							kv.GetString("key", keyValueInfo.key, sizeof(KeyValueInfo::key));
							kv.GetString("value", keyValueInfo.value, sizeof(KeyValueInfo::value));
							
							if (kv.GetNum("output"))
							{
								PrepareOutputAction(keyValueInfo.value, sizeof(KeyValueInfo::value));
							}
							
							g_List_KeyValues.PushArray(keyValueInfo);
						}
						while (kv.GotoNextKey(false));
						kv.GoBack();
					}
					
					kv.GoBack();
					
					int pos = -1;							
					while ((pos = FindLumpEntryByKeyValues(pos, g_List_KeyValues)) != -1)
					{
						g_List_LumpEntriesPosition.Push(pos);
					}
					
					ClearArray_Ex(g_List_KeyValues);
					
					if (kv.JumpToKey("delete"))
					{
						if (kv.GotoFirstSubKey(false))
						{
							do
							{
								KeyValueInfo keyValueInfo;
								kv.GetString("key", keyValueInfo.key, sizeof(KeyValueInfo::key));
								kv.GetString("value", keyValueInfo.value, sizeof(KeyValueInfo::value));
								
								if (kv.GetNum("output"))
								{
									PrepareOutputAction(keyValueInfo.value, sizeof(KeyValueInfo::value));
								}
								
								bool hasValue;
								if (kv.JumpToKey("value"))
								{
									hasValue = true;
									kv.GoBack();
								}
								
								for (int i = 0; i < g_List_LumpEntriesPosition.Length; i++)
								{
									pos = g_List_LumpEntriesPosition.Get(i);
									EntityLumpEntry lumpEntry = EntityLump.Get(pos);
									
									DeleteKeyValueFromLumpEntry(lumpEntry, keyValueInfo, hasValue);
									delete lumpEntry;
								}
							}
							while (kv.GotoNextKey(false));
							kv.GoBack();
						}
						
						kv.GoBack();
					}
					
					if (kv.JumpToKey("modify"))
					{
						if (kv.GotoFirstSubKey(false))
						{
							do
							{
								KeyValueInfo keyValueInfo;
								kv.GetString("key", keyValueInfo.key, sizeof(KeyValueInfo::key));
								kv.GetString("value", keyValueInfo.value, sizeof(KeyValueInfo::value));
								
								char oldValue[512];
								kv.GetString("old_value", oldValue, sizeof(oldValue));
								
								if (kv.GetNum("output"))
								{
									PrepareOutputAction(keyValueInfo.value, sizeof(KeyValueInfo::value));
									PrepareOutputAction(oldValue, sizeof(oldValue));
								}
								
								bool hasOldValue;
								if (kv.JumpToKey("old_value"))
								{
									hasOldValue = true;
									kv.GoBack();
								}
								
								char buffer[512];
								kv.GetString("value_type", buffer, sizeof(buffer));
								
								ValueType valueType;
								g_Map_ValueTypes.GetValue(buffer, valueType);
								
								for (int i = 0; i < g_List_LumpEntriesPosition.Length; i++)
								{
									pos = g_List_LumpEntriesPosition.Get(i);
									EntityLumpEntry lumpEntry = EntityLump.Get(pos);
									
									UpdateKeyValueFromLumpEntry(lumpEntry, keyValueInfo, oldValue, hasOldValue, valueType);
									delete lumpEntry;
								}
							}
							while (kv.GotoNextKey(false));
							kv.GoBack();
						}
						
						kv.GoBack();
					}
					
					if (kv.JumpToKey("add"))
					{
						if (kv.GotoFirstSubKey(false))
						{
							do
							{
								KeyValueInfo keyValueInfo;
								kv.GetString("key", keyValueInfo.key, sizeof(KeyValueInfo::key));
								kv.GetString("value", keyValueInfo.value, sizeof(KeyValueInfo::value));
								
								if (kv.GetNum("output"))
								{
									PrepareOutputAction(keyValueInfo.value, sizeof(KeyValueInfo::value));
								}
								
								for (int i = 0; i < g_List_LumpEntriesPosition.Length; i++)
								{
									pos = g_List_LumpEntriesPosition.Get(i);
									EntityLumpEntry lumpEntry = EntityLump.Get(pos);
									
									lumpEntry.Append(keyValueInfo.key, keyValueInfo.value);
									delete lumpEntry;
								}
							}
							while (kv.GotoNextKey(false));
							kv.GoBack();
						}
						
						kv.GoBack();
					}
					
					ClearArray_Ex(g_List_LumpEntriesPosition);
				}
				while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
		
		if (kv.JumpToKey("Add Entities"))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					int pos = EntityLump.Append();
					EntityLumpEntry lumpEntry = EntityLump.Get(pos);
					
					if (kv.GotoFirstSubKey(false))
					{
						do
						{
							KeyValueInfo keyValueInfo;
							kv.GetString("key", keyValueInfo.key, sizeof(KeyValueInfo::key));
							kv.GetString("value", keyValueInfo.value, sizeof(KeyValueInfo::value));
							
							if (kv.GetNum("output"))
							{
								PrepareOutputAction(keyValueInfo.value, sizeof(KeyValueInfo::value));
							}
							
							lumpEntry.Append(keyValueInfo.key, keyValueInfo.value);
						}
						while (kv.GotoNextKey(false));
						kv.GoBack();
					}
					
					delete lumpEntry;
				}
				while (kv.GotoNextKey(false));
			}
			
			kv.Rewind();
		}
	}
	
	delete kv;
}

public Action Command_DumpEntityLump(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_dump_entitylump <file>");
		return Plugin_Handled;
	}
	
	char fileName[PLATFORM_MAX_PATH];
	GetCmdArgString(fileName, sizeof(fileName));
	StripQuotes(fileName);
	
	File file = OpenFile(fileName, "wt");
	if (!file)
	{
		ReplyToCommand(client, "[SM] Could not open file \"%s\"", fileName);
		return Plugin_Handled;
	}
	
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	file.WriteLine("Map entities (%s)", currentMap);
	file.WriteLine("");
	
	for (int i = 0; i < EntityLump.Length(); i++)
	{
		KeyValueInfo keyValueInfo;
		EntityLumpEntry lumpEntry = EntityLump.Get(i);
		
		for (int j = 0; j < lumpEntry.Length; j++)
		{
			lumpEntry.Get(j, keyValueInfo.key, sizeof(KeyValueInfo::key), keyValueInfo.value, sizeof(KeyValueInfo::value));
			FormatOutputAction(keyValueInfo.value, sizeof(KeyValueInfo::value));
			
			file.WriteLine("- %s: %s", keyValueInfo.key, keyValueInfo.value);
		}
		
		file.WriteLine("");
		delete lumpEntry;
	}
	
	delete file;	
	return Plugin_Handled;
}

void FormatOutputAction(char[] outputAction, int maxLen)
{
	ReplaceString(outputAction, maxLen, g_OutputActionSeparator, ":");
}

void PrepareOutputAction(char[] outputAction, int maxLen)
{
	if (!strncmp(outputAction, "AddOutput ", 10, false))
	{
		return;
	}
	
	ReplaceString(outputAction, maxLen, ":", g_OutputActionSeparator);
}

void DeleteKeyValueFromLumpEntry(EntityLumpEntry lumpEntry, KeyValueInfo keyValueInfo, bool hasValue)
{
	int pos = -1;
	while ((pos = lumpEntry.FindKey(keyValueInfo.key, pos)) != -1)
	{
		if (hasValue)
		{
			char value[512];
			lumpEntry.Get(pos, _, 0, value, sizeof(value));
			
			if (!StrEqual(keyValueInfo.value, value, true))
			{
				continue;
			}
		}
		
		lumpEntry.Erase(pos);
	}
}

void UpdateKeyValueFromLumpEntry(EntityLumpEntry lumpEntry, KeyValueInfo keyValueInfo, const char[] oldValue, bool hasOldValue, ValueType valueType)
{
	int pos = -1;
	while ((pos = lumpEntry.FindKey(keyValueInfo.key, pos)) != -1)
	{
		char value[512];
		lumpEntry.Get(pos, _, 0, value, sizeof(value));
		
		if (hasOldValue && !StrEqual(oldValue, value, true))
		{
			continue;
		}
		
		switch (valueType)
		{
			case ValueType_Min:
			{
				int valueInt = StringToInt(value);
				int minValue = StringToInt(keyValueInfo.value);
				
				if (valueInt >= minValue)
				{
					continue;
				}
				
				strcopy(value, sizeof(value), keyValueInfo.value);
			}
			
			case ValueType_Max:
			{
				int valueInt = StringToInt(value);
				int maxValue = StringToInt(keyValueInfo.value);
				
				if (valueInt <= maxValue)
				{
					continue;
				}
				
				strcopy(value, sizeof(value), keyValueInfo.value);
			}
			
			case ValueType_AddFlags:
			{
				int valueInt = StringToInt(value);
				int addFlags = StringToInt(keyValueInfo.value);
				
				valueInt |= addFlags;
				IntToString(valueInt, value, sizeof(value));
			}
			
			case ValueType_SubstractFlags:
			{
				int valueInt = StringToInt(value);
				int substractFlags = StringToInt(keyValueInfo.value);
				
				valueInt &= ~substractFlags;
				IntToString(valueInt, value, sizeof(value));
			}
			
			default:
			{
				strcopy(value, sizeof(value), keyValueInfo.value);
			}
		}
		
		lumpEntry.Update(pos, NULL_STRING, value);
	}
}

bool AreKeyValuesInLumpEntry(EntityLumpEntry lumpEntry, ArrayList listKeyValues)
{
	KeyValueInfo keyValueInfo;
	for (int j = 0; j < listKeyValues.Length; j++)
	{
		listKeyValues.GetArray(j, keyValueInfo);
		
		bool isKeyInLumpEntry;
		bool isValueInLumpEntry;
		
		int pos = -1;
		while ((pos = lumpEntry.FindKey(keyValueInfo.key, pos)) != -1)
		{
			isKeyInLumpEntry = true;
			
			char value[512];
			lumpEntry.Get(pos, _, 0, value, sizeof(value));
			
			if (StrEqual(value, keyValueInfo.value, true))
			{
				isValueInLumpEntry = true;
				break;
			}
		}
		
		if (!isKeyInLumpEntry || !isValueInLumpEntry)
		{
			return false;
		}
	}
	
	return true;
}

int FindLumpEntryByKeyValues(int start, ArrayList listKeyValues)
{
	for (int i = start + 1; i < EntityLump.Length(); i++)
	{
		EntityLumpEntry lumpEntry = EntityLump.Get(i);
		bool result = AreKeyValuesInLumpEntry(lumpEntry, listKeyValues);
		
		delete lumpEntry;
		if (result)
		{
			return i;
		}
	}
	
	return -1;
}