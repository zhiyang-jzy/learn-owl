// ======================================================================== //
// Copyright 2019-2020 Ingo Wald                                            //
//                                                                          //
// Licensed under the Apache License, Version 2.0 (the "License");          //
// you may not use this file except in compliance with the License.         //
// You may obtain a copy of the License at                                  //
//                                                                          //
//     http://www.apache.org/licenses/LICENSE-2.0                           //
//                                                                          //
// Unless required by applicable law or agreed to in writing, software      //
// distributed under the License is distributed on an "AS IS" BASIS,        //
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. //
// See the License for the specific language governing permissions and      //
// limitations under the License.                                           //
// ======================================================================== //

#include "device_code.h"
#include <optix_device.h>

OPTIX_RAYGEN_PROGRAM(simpleRayGen)()
{
    const RayGenData &self = owl::getProgramData<RayGenData>();
    const vec2i pixelID = owl::getLaunchIndex();
    if (pixelID == owl::vec2i(0)) {
        printf("%sHello OptiX From your First RayGen Program%s\n",
               OWL_TERMINAL_CYAN,
               OWL_TERMINAL_DEFAULT);
    }

    vec3f light_pos(3,3,3);

    const vec2f screen = (vec2f(pixelID)+vec2f(.5f)) / vec2f(self.fbSize);
    owl::Ray ray;
    ray.origin
            = self.camera.pos;
    ray.direction
            = normalize(self.camera.dir_00
                        + screen.u * self.camera.dir_du
                        + screen.v * self.camera.dir_dv);

    RayData rayData;
    owl::traceRay(/*accel to trace against*/self.world,
            /*the ray to trace*/ray,
            /*prd*/rayData);

    vec3f color(1,1,1);

    const int fbOfs = pixelID.x+self.fbSize.x*pixelID.y;
    if(rayData.hit)
    {

        vec3f normal = normalize(rayData.normal);
        vec3f light_dir = normalize(light_pos-rayData.point);
        vec3f view_dir = normalize(ray.origin-rayData.point);
        vec3f halfway_dir = normalize(light_dir+view_dir);

        vec3f ambient = 0.05f * color;//环境光


        float diff = max(dot(light_dir,normal), 0.f);
        vec3f diffuse = diff * color; //漫反射

        float spec = pow(max(dot(normal,halfway_dir), 0.f), 128);
        vec3f specular = vec3f(0.3, 0.3, 0.3) * spec;// 镜面反射

        vec3f res = ambient + diffuse + specular;


        self.fbPtr[fbOfs]
                = owl::make_rgba(res);
    }
    else
        self.fbPtr[fbOfs] = owl::make_rgba(vec3f(0));
}

OPTIX_CLOSEST_HIT_PROGRAM(TriangleMesh)()
{
    RayData &prd = owl::getPRD<RayData>();

    const TrianglesGeomData &self = owl::getProgramData<TrianglesGeomData>();

    // compute normal:
    const int   primID = optixGetPrimitiveIndex();
    const vec3i index  = self.index[primID];

//    const vec3f Ng     = normalize(cross(B-A,C-A));
    vec2f uv =  optixGetTriangleBarycentrics();
    vec3f normal
            = (1.f-uv.x-uv.y)*self.normal[index.x]
              +      uv.x      *self.normal[index.y]
              +           uv.y *self.normal[index.z];
    normal = normalize(normal);
    optixTransformNormalFromObjectToWorldSpace(normal);

    const vec3f org  = optixGetWorldRayOrigin();
    const vec3f dir  = optixGetWorldRayDirection();
    const float hit_t = optixGetRayTmax();
    const vec3f hit_P = org + hit_t * dir;
    prd.normal = normal;
    prd.point = hit_P;
    prd.hit = true;

}

OPTIX_MISS_PROGRAM(miss)()
{
    const vec2i pixelID = owl::getLaunchIndex();

    const MissProgData &self = owl::getProgramData<MissProgData>();

    RayData &prd = owl::getPRD<RayData>();
    int pattern = (pixelID.x / 8) ^ (pixelID.y/8);
    prd.hit = false;

}

