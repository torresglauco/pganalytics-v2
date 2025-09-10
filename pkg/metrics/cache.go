package metrics

import (
    "sync"
    "time"
)

type CacheConfig struct {
    TTL         time.Duration
    CleanupInterval time.Duration
}

type Cache struct {
    data    map[string]CacheItem
    mutex   sync.RWMutex
    config  CacheConfig
    stop    chan bool
}

type CacheItem struct {
    Value     interface{}
    ExpiresAt time.Time
}

func NewCache(config CacheConfig) *Cache {
    c := &Cache{
        data:   make(map[string]CacheItem),
        config: config,
        stop:   make(chan bool),
    }
    
    go c.cleanupExpired()
    return c
}

func (c *Cache) Set(key string, value interface{}) {
    c.mutex.Lock()
    defer c.mutex.Unlock()
    
    c.data[key] = CacheItem{
        Value:     value,
        ExpiresAt: time.Now().Add(c.config.TTL),
    }
}

func (c *Cache) Get(key string) (interface{}, bool) {
    c.mutex.RLock()
    defer c.mutex.RUnlock()
    
    item, exists := c.data[key]
    if !exists || time.Now().After(item.ExpiresAt) {
        return nil, false
    }
    
    return item.Value, true
}

func (c *Cache) cleanupExpired() {
    ticker := time.NewTicker(c.config.CleanupInterval)
    defer ticker.Stop()
    
    for {
        select {
        case <-ticker.C:
            c.removeExpired()
        case <-c.stop:
            return
        }
    }
}

func (c *Cache) removeExpired() {
    c.mutex.Lock()
    defer c.mutex.Unlock()
    
    now := time.Now()
    for key, item := range c.data {
        if now.After(item.ExpiresAt) {
            delete(c.data, key)
        }
    }
}

func (c *Cache) Close() {
    close(c.stop)
}
