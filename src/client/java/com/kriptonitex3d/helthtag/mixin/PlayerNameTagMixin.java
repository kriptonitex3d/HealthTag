package com.kriptonitex3d.helthtag.mixin;

import net.minecraft.ChatFormatting;
import net.minecraft.client.renderer.entity.player.AvatarRenderer;
import net.minecraft.client.renderer.entity.state.AvatarRenderState;
import net.minecraft.network.chat.Component;
import net.minecraft.world.entity.Avatar;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(AvatarRenderer.class)
public class PlayerNameTagMixin {
	@Inject(method = "extractRenderState(Lnet/minecraft/world/entity/Avatar;Lnet/minecraft/client/renderer/entity/state/AvatarRenderState;F)V", at = @At("TAIL"))
	private void helthtag$extractHealthNameTag(Avatar player, AvatarRenderState state, float partialTick, CallbackInfo ci) {
		if (state.nameTagAttachment == null) {
			return;
		}

		int hearts = (int) Math.ceil(player.getHealth() / 2.0F);
		state.scoreText = Component.literal(hearts + " ")
			.append(Component.literal("\u2764").withStyle(ChatFormatting.RED));
	}
}
