public with sharing class ERMT_RecordTypeCache
{
    public static Map<String, RecordType> get(SObjectType key)
    {
        return cache.containsKey(key) ? cache.get(key) : new Map<String, RecordType>();
    }
    public static RecordType get(SObjectType key, String developerName)
    {
        return get(key).get(developerName);
    }

    static Map<SObjectType, Map<String, RecordType>> cache
    {
        get
        {
            if (cache == null)
            {
                cache = new Map<SObjectType, Map<String, RecordType>>();
                Map<String, SObjectType> objects = Schema.getGlobalDescribe();
                for (RecordType recordType : [SELECT Name, DeveloperName, SObjectType FROM RecordType Order By Name Limit 100 ])
                {
                    SObjectType schemaType = objects.get(recordType.SObjectType);
                    if (!cache.containsKey(schemaType))
                        cache.put(schemaType, new Map<String, RecordType>());
                    cache.get(schemaType).put(recordType.DeveloperName, recordType);
                }
            }
            return cache;
        }
        private set;
    }
}