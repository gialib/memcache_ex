defmodule Memcache.ClientTest do
  use ExUnit.Case, async: false

  setup do
    flush_response = Memcache.Client.flush
    flush_response.status

    :ok
  end

  test "get key not found" do
    get_response = Memcache.Client.get("key")
    assert get_response.status == :key_not_found
  end
  
  test "set key" do
    set_response = Memcache.Client.set("key", "value")
    assert set_response.extras == ""
    assert set_response.status == :ok

    get_response = Memcache.Client.get("key")
    assert get_response.cas == set_response.cas
    assert get_response.value == "value"
  end

  test "set key with cas" do
    set_response = Memcache.Client.set("key", "value")
    cas = set_response.cas

    set_response = Memcache.Client.set("key", "other value", cas: cas)
    assert set_response.status == :ok
    assert set_response.cas != cas

    set_response = Memcache.Client.set("key", "yet another value", cas: 1234567)
    assert set_response.status == :key_exists
  end

  test "set key with expiry" do
    set_response = Memcache.Client.set("key", "value", expires: 1000)
    assert set_response.status == :ok

    get_response = Memcache.Client.get("key")
    assert get_response.status == :ok
    assert get_response.value == "value"
  end
  
  test "add key" do
    add_response = Memcache.Client.add("key", "value")
    assert add_response.extras == ""
    assert add_response.status == :ok

    get_response = Memcache.Client.get("key") 
    assert get_response.cas == add_response.cas 
    assert get_response.value == "value"
    
    # try add when already existing
    add_response = Memcache.Client.add("key", "other value")
    assert add_response.status == :key_exists
  end

  test "replace key" do
    replace_response = Memcache.Client.replace("key", "value")
    assert replace_response.status == :key_not_found

    set_response = Memcache.Client.set("key", "value")
    assert set_response.status == :ok

    replace_response = Memcache.Client.replace("key", "value")
    assert replace_response.status == :ok
    assert replace_response.cas != set_response.cas
  end

  test "increment key" do
    incr_response = Memcache.Client.increment("key", 1)
    assert incr_response.status == :ok
    assert incr_response.value == 0

    incr_response = Memcache.Client.increment("key", 1)
    assert incr_response.status == :ok
    assert incr_response.value == 1

    incr_response = Memcache.Client.increment("key", 10)
    assert incr_response.status == :ok
    assert incr_response.value == 11
  end

  test "increment key with initial value" do
    incr_response = Memcache.Client.increment("key", 10, initial_value: 100)
    assert incr_response.status == :ok
    assert incr_response.value == 100

    incr_response = Memcache.Client.increment("key", 10)
    assert incr_response.status == :ok
    assert incr_response.value == 110
  end

  test "decrement key" do
    decr_response = Memcache.Client.decrement("key", 10)
    assert decr_response.status == :ok
    assert decr_response.value == 0

    decr_response = Memcache.Client.decrement("key", 10)
    assert decr_response.status == :ok
    assert decr_response.value == 0
  end

  test "decrement key with initial value" do
    decr_response = Memcache.Client.decrement("key", 10, initial_value: 100)
    assert decr_response.status == :ok
    assert decr_response.value == 100

    decr_response = Memcache.Client.decrement("key", 10)
    assert decr_response.status == :ok
    assert decr_response.value == 90
  end

  test "delete key" do
    delete_response = Memcache.Client.delete("key")
    assert delete_response.status == :key_not_found

    set_response = Memcache.Client.set("key", "value")
    assert set_response.status == :ok

    delete_response = Memcache.Client.delete("key")
    assert delete_response.status == :ok

    get_response = Memcache.Client.get("key")
    assert get_response.status == :key_not_found
  end

  test "append" do
    append_response = Memcache.Client.append("key", "value")
    assert append_response.status == :item_not_stored
    
    set_response = Memcache.Client.set("key", "value")
    assert set_response.status == :ok

    append_response = Memcache.Client.append("key", " value")
    assert append_response.status == :ok

    get_response = Memcache.Client.get("key")
    assert get_response.value == "value value"
  end

  test "prepend" do
    prepend_response = Memcache.Client.prepend("key", "value")
    assert prepend_response.status == :item_not_stored
    
    set_response = Memcache.Client.set("key", "value")
    assert set_response.status == :ok

    prepend_response = Memcache.Client.prepend("key", "value ")
    assert prepend_response.status == :ok
    
    get_response = Memcache.Client.get("key")
    assert get_response.value == "value value"
  end

  test "multi get" do
    keys = ["test1", "test2", "test3"]
    [mget_response] = Memcache.Client.mget(keys) |> Enum.into([])
    assert mget_response.status == :key_not_found

    set_response = Memcache.Client.set("key1", "value1")
    assert set_response.status == :ok

    set_response = Memcache.Client.set("key2", "value2")
    assert set_response.status == :ok

    keys = ["key1", "key2", "key3"]
    [response1, response2, response3] = Memcache.Client.mget(keys) |> Enum.into([])
    assert response1.status == :ok
    assert response1.value == "value1"
    assert response2.status == :ok
    assert response2.value == "value2"
    assert response3.status == :key_not_found
  end

  test "multi set" do
    keyvals = [{"key1", "value1"}, {"key2", "value2"}]
    [mset_response] = Memcache.Client.mset(keyvals) |> Enum.into([])
    assert mset_response.status == :ok

    get_response = Memcache.Client.get("key1")
    assert get_response.status == :ok
    assert get_response.value == "value1"

    get_response = Memcache.Client.get("key2")
    assert get_response.status == :ok
    assert get_response.value == "value2"
  end
  
end
