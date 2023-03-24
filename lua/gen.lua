-- ./wrk/wrk -t1 -c1 -d 10s http://10.96.88.88:8080 -L -s ./scripts/lua/bookinfo.lua


local function productpage()
    local method = "GET"
    local path = "http://10.107.166.197:8080/productpage"
    local headers = {}
    return wrk.format(method, path, headers, nil)
end


request = function()
    return productpage()
end

response = function(status, headers, body)
    if status ~= 200 then
        print(body)
    end
end

-- https://gist.github.com/YutaroHayakawa/7f4a1447bc7d66bb42cd529dfe93a329
done = function(summary, latency, requests)
    -- open output file
    f = io.open("result.csv", "a+")
    
    -- write below results to file
    --   minimum latency
    --   max latency
    --   mean of latency
    --   standard deviation of latency
    --   50percentile latency
    --   90percentile latency
    --   99percentile latency
    --   99.999percentile latency
    --   duration of the benchmark
    --   total requests during the benchmark
    --   total received bytes during the benchmark
    
    -- f:write(string.format("%f,%f,%f,%f,%f,%f,%f,%f,%d,%d,%d\n",
    -- latency.min, latency.max, latency.mean, latency.stdev, latency:percentile(50),
    -- latency:percentile(90), latency:percentile(99), latency:percentile(99.999),
    -- summary["duration"], summary["requests"], summary["bytes"]))
    
    -- ms, byte
    f:write(string.format("%f,%f,%f,%f,%f,%d,%d,%d\n",
    latency.mean, latency.stdev, latency:percentile(50),
    latency:percentile(90), latency:percentile(99),
    summary["duration"], summary["requests"], summary["bytes"]))
    f:close()
  end