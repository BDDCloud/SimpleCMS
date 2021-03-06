﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Routing;
using RestfulRouting;
using SimpleCMS.Core.Controllers;

namespace SimpleCMS.Core.Web {
    public class Routes : RouteSet {
        public override void Map(IMapper map) {
            // ReSharper disable ConvertToLambdaExpression
            map.Root<HomeController>(x => x.Index());
            map.Resources<PostsController>(posts => {
                posts.Collection(x => {
                    x.Get("search");
                    x.Post("search");
                });
		    });
            map.Resources<AccountsController>(accounts => {
                accounts.As("users");
                accounts.Member(x => x.Post("update"));
            });
            // ReSharper restore ConvertToLambdaExpression
        }
    }

    public static class RouteTableExtension {
        public static void WriteRoutes(this RouteCollection routes, Action<string> writeAction) {
            foreach (var route in RouteTable.Routes) {
                writeAction(BuildRoute(route));
            }
        }

        static string BuildRoute(RouteBase routeBase) {
            var route = ((Route)routeBase);
            var allowedMethods = ((HttpMethodConstraint)route.Constraints["httpMethod"]).AllowedMethods;
            return string.Format("{0} {1} => {2}#{3}",
                                 DisplayAllowedMethods(allowedMethods),
                                 string.IsNullOrEmpty(route.Url) ? "/" : route.Url,
                                 route.Defaults["controller"],
                                 route.Defaults["action"]);
        }

        static string DisplayAllowedMethods(IEnumerable<string> allowedMethods)
        {
            var strings = allowedMethods
                .ToList()
                .Select(p => p.ToString())
                .ToArray();
            return String.Join(", ", strings);
        }
    }
}