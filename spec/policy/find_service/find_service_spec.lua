local FindService = require('apicast.policy.find_service')
local HostBasedFinder = require('apicast.policy.find_service.host_based_finder')
local PathBasedFinder = require('apicast.policy.find_service.path_based_finder')
local ConfigurationStore = require('apicast.configuration_store')

describe('find_service', function()
  describe('.rewrite', function()
    describe('when path routing is enabled', function()
      describe('and there is a service with a matching path', function()
        it('stores that service in the context', function()
          ConfigurationStore.path_routing = true
          local service = { id = '1' }
          local context = { configuration = ConfigurationStore.new(), host = 'example.com' }
          stub(PathBasedFinder, 'find_service', function(config_store, host)
            if config_store == context.configuration and host == context.host then
              return service
            end
          end)
          stub(HostBasedFinder, 'find_service')
          local find_service = FindService.new()

          find_service:rewrite(context)

          assert.stub(HostBasedFinder.find_service).was_not_called()
          assert.equals(service, context.service)
        end)
      end)

      describe('and there is not a service with a matching path', function()
        it('fallbacks to find a service by host and stores it in the context', function()
          ConfigurationStore.path_routing = true
          local service = { id = '1' }
          local context = { configuration = ConfigurationStore.new(), host = 'example.com' }
          stub(PathBasedFinder, 'find_service', function() return nil end)
          stub(HostBasedFinder, 'find_service', function(config_store, host)
            if config_store == context.configuration and host == context.host then
              return service
            end
          end)

          local find_service = FindService.new()

          find_service:rewrite(context)

          assert.equals(service, context.service)
        end)

        it('stores nil in the context if there is not a service for the host', function()
          ConfigurationStore.path_routing = true
          local context = { }
          stub(PathBasedFinder, 'find_service', function() return nil end)
          stub(HostBasedFinder, 'find_service', function() return nil end)

          local find_service = FindService.new()

          find_service:rewrite(context)

          assert.is_nil(context.service)
        end)
      end)
    end)

    describe('when path routing is disabled', function()
      it('finds the service by host and stores it in the context', function()
        ConfigurationStore.path_routing = false
        local service = { id = '1' }
        local context = { configuration = ConfigurationStore.new(), host = 'example.com' }
        stub(HostBasedFinder, 'find_service', function(config_store, host)
          if config_store == context.configuration and host == context.host then
            return service
          end
        end)
        stub(PathBasedFinder, 'find_service')
        local find_service = FindService.new()

        find_service:rewrite(context)

        assert.stub(PathBasedFinder.find_service).was_not_called()
        assert.equals(service, context.service)
      end)

      it('stores nil in the context if there is not a service for the host', function()
        ConfigurationStore.path_routing = false
        local context = { }
        stub(HostBasedFinder, 'find_service', function() return nil end)
        local find_service = FindService.new()

        find_service:rewrite(context)

        assert.is_nil(context.service)
      end)
    end)
  end)
end)
