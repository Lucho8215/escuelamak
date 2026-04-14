import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS"
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    if (!Deno.env.get("SUPABASE_URL") || !Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")) {
      return new Response(
        JSON.stringify({
          error: "Faltan secrets SUPABASE_URL o SUPABASE_SERVICE_ROLE_KEY"
        }),
        {
          status: 500,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          }
        }
      );
    }

    if (body.action === "create-user") {
      const { name, email, cedula, role, password } = body;

      const { data: authUser, error: authError } =
        await supabase.auth.admin.createUser({
          email,
          password,
          email_confirm: true
        });

      if (authError || !authUser.user) {
        return new Response(
          JSON.stringify({
            error: authError?.message || "No se pudo crear el usuario en autenticación"
          }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json"
            }
          }
        );
      }

      const { data, error } = await supabase
        .from("app_users")
        .insert({
          auth_user_id: authUser.user.id,
          name,
          email,
          cedula,
          role
        })
        .select()
        .single();

      if (error) {
        await supabase.auth.admin.deleteUser(authUser.user.id);

        return new Response(
          JSON.stringify({
            error: `Se creó en autenticación pero falló en app_users: ${error.message}`
          }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json"
            }
          }
        );
      }

      return new Response(
        JSON.stringify({ user: data }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          }
        }
      );
    }

    if (body.action === "update-user") {
      const { id, name, email, cedula, role } = body;

      const { data, error } = await supabase
        .from("app_users")
        .update({
          name,
          email,
          cedula,
          role
        })
        .eq("id", id)
        .select()
        .single();

      if (error) {
        return new Response(
          JSON.stringify({ error: error.message }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json"
            }
          }
        );
      }

      return new Response(
        JSON.stringify({ user: data }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          }
        }
      );
    }

    if (body.action === "update-password") {
      const { userId, password } = body;

      const { data: user, error: userError } = await supabase
        .from("app_users")
        .select("auth_user_id")
        .eq("id", userId)
        .single();

      if (userError || !user?.auth_user_id) {
        return new Response(
          JSON.stringify({
            error: userError?.message || "Usuario sin auth_user_id"
          }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json"
            }
          }
        );
      }

      const { error } = await supabase.auth.admin.updateUserById(
        user.auth_user_id,
        { password }
      );

      if (error) {
        return new Response(
          JSON.stringify({ error: error.message }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json"
            }
          }
        );
      }

      return new Response(
        JSON.stringify({ success: true }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          }
        }
      );
    }

    if (body.action === "delete-user") {
      const { id } = body;

      const { data: user, error: userError } = await supabase
        .from("app_users")
        .select("auth_user_id")
        .eq("id", id)
        .single();

      if (userError || !user?.auth_user_id) {
        return new Response(
          JSON.stringify({
            error: userError?.message || "No se encontró el usuario en app_users"
          }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json"
            }
          }
        );
      }

      const { error: authDeleteError } = await supabase.auth.admin.deleteUser(
        user.auth_user_id
      );

      if (authDeleteError) {
        return new Response(
          JSON.stringify({ error: authDeleteError.message }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json"
            }
          }
        );
      }

      const { error: deleteError } = await supabase
        .from("app_users")
        .delete()
        .eq("id", id);

      if (deleteError) {
        return new Response(
          JSON.stringify({ error: deleteError.message }),
          {
            status: 400,
            headers: {
              ...corsHeaders,
              "Content-Type": "application/json"
            }
          }
        );
      }

      return new Response(
        JSON.stringify({ success: true }),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            "Content-Type": "application/json"
          }
        }
      );
    }

    return new Response(
      JSON.stringify({ error: "Acción inválida" }),
      {
        status: 400,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      }
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : "Error desconocido";

    return new Response(
      JSON.stringify({ error: message }),
      {
        status: 500,
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      }
    );
  }
});