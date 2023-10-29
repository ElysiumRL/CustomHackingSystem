module CustomHackingSystem.Tools

// A very simple, naive (and definetly not optimized) dictionary implementation (Key - CName, Value - ref<IScriptable>)
// Still waiting for generic type support for redscript in order to make it somehow a bit more "universal"

// I don't want to implement a whole hash system with buckets mostly because it would be a bit annoying to make it
// fit with all the existing IScriptable classes (and native classes too) without breaking the whole code

public class CNameIScriptableDictionary extends IScriptable
{
    protected let keys: array<CName>;
    protected let values: array<ref<IScriptable>>;

    // Returns the value associated to this key or null if it can't be found
    public func Get(key: CName) -> ref<IScriptable>
    {
        let i:Int32 = 0;
        while(i < ArraySize(this.keys))
        {
            if Equals(this.keys[i],key)
            {
                return this.values[i];
            }
            i += 1;
        }
        return null;
    }

    // Inserts a new key into this dictionary. If the key already exists, it will override the value instead
    public func Insert(key: CName, value: ref<IScriptable>) -> Void
    {
        if (!ArrayContains(this.keys,key))
        {
            ArrayPush(this.keys,key);
            ArrayPush(this.values,value);
        }
        else
        {
            this.Set(key, value);
        } 
    }

    // Overrides the value in an already existing key
    public func Set(key: CName, value: ref<IScriptable>) -> Void
    {
        let i:Int32 = 0;
        while(i < ArraySize(this.keys))
        {
            if Equals(this.keys[i],key)
            {
                this.values[i] = value;
            }
            i += 1;
        }
    }

    // Returns true if a key is already contained in this dictionary
    public func KeyExists(key: CName) -> Bool
    {
        return ArrayContains(this.keys,key);
    }

    // Removes a key from this dictionary
    public func Remove(key: CName) -> Void
    {
        let i:Int32 = 0;
        let keyFound: Bool = false;
        let keyToRemove: CName;
        let valueToRemove: ref<IScriptable> = null;
        while(i < ArraySize(this.keys))
        {
            if Equals(this.keys[i],key)
            {
                keyFound = true;
                keyToRemove = this.keys[i];
                valueToRemove = this.values[i];
                break;
            }
            i += 1;
        }
        if (keyFound)
        {
            ArrayRemove(this.keys,keyToRemove);
            ArrayRemove(this.values,valueToRemove);
        }
    }

    // Clears all the keys & values
    public func Clear() -> Void
    {
        ArrayClear(this.keys);
        ArrayClear(this.values);
    }

    // Returns all the keys
    public func GetKeys() -> array<CName>
    {
        return this.keys;
    }

    // Returns all the values
    public func GetValues() -> array<ref<IScriptable>>
    {
        return this.values;
    }
}