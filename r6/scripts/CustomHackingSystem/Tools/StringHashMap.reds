module CustomHackingSystem.Tools

//this is the wrong name it's not a hashmap, it's more of a dictionary/set than anything else
//and it also is a kinda badly optimized one on top of that
public class StringHashMap extends IScriptable
{
    protected let keys: array<String>;
    protected let values: array<ref<IScriptable>>;

    public final func Insert(key: String, value: ref<IScriptable>) -> Void
    {
        if !ArrayContains(this.keys,key)
        {
            ArrayPush(this.keys,key);
            ArrayResize(this.values,ArraySize(this.keys));
        }
        this.Set(key, value);
        
    }
    
    public final func Get(key: String) -> wref<IScriptable>
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

    public final func Set(key: String, value: ref<IScriptable>) -> Void
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

    public final func KeyExist(key: String) -> Bool
    {
        let i:Int32 = 0;
        while(i < ArraySize(this.keys))
        {
            if Equals(this.keys[i],key)
            {
                return true;
            }
            i += 1;
        }
        return false;
    }

    public final func Remove(key: String) -> Void
    {
        let i:Int32 = 0;
        let keyFound: Bool = false;
        let keyToRemove: String = "";
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
        if(keyFound)
        {
            ArrayRemove(this.keys,keyToRemove);
            ArrayRemove(this.values,valueToRemove);
        }
    }

    public final func Clear() -> Void
    {
        ArrayClear(this.keys);
        ArrayClear(this.values);
    }

    public final func GetValues(out values: array<ref<IScriptable>>) -> Void
    {
        values = this.values;
    }

}