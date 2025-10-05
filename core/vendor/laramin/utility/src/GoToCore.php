<?php

namespace Laramin\Utility;

use Closure;

class GoToCore{

    public function handle($request, Closure $next)
    {
        return $next($request);
    }
}
