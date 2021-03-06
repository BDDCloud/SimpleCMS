﻿using System;
using System.Web.Mvc;
using System.Web.Routing;

namespace SimpleCMS.Core.Controllers
{
    public class CustomControllerFactory : DefaultControllerFactory {
        protected override IController GetControllerInstance(RequestContext requestContext, Type controllerType)
        {
            return (IController) Ioc.Resolve(controllerType);
        }
    }
}